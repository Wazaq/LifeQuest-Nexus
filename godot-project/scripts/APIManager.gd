# APIManager.gd - Singleton for LifeQuest API Communication
# Handles all communication with our deployed quest generation API

extends Node

# API Configuration
const API_BASE_URL = "https://lifequest-api.wazaqglim.workers.dev"

# User session management
var current_user_id: String = ""
var jwt_token: String = ""
var google_user_data: Dictionary = {}
var is_authenticated: bool = false

# Authentication modes
enum AuthMode {
	LEGACY_USER_ID,  # Original X-User-ID system
	OAUTH_JWT        # New Google OAuth with JWT
}
var current_auth_mode: AuthMode = AuthMode.LEGACY_USER_ID

# Signals for UI to listen to
signal quest_generated(quest_data)
signal quest_completed(result)
signal profile_updated(profile_data)
signal api_error(error_message)
signal user_created(user_data)
signal oauth_login_ready(auth_url)
signal oauth_login_success(user_data)
signal oauth_login_failed(error_message)
signal authentication_state_changed(is_authenticated)

# HTTP request node
var http_request: HTTPRequest

func _ready():
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("LifeQuest API Manager initialized")
	print("API Base URL: ", API_BASE_URL)
	
	# Check for OAuth callback parameters first
	check_oauth_callback_parameters()
	
	# Initialize user session
	initialize_user_session()

# Check for OAuth callback parameters in URL
func check_oauth_callback_parameters():
	"""Check if the app was loaded with OAuth callback parameters"""
	# In Godot web builds, we can access URL parameters via JavaScript
	if OS.has_feature("web"):
		var js_code = """
		(function() {
			var urlParams = new URLSearchParams(window.location.search);
			var result = {};
			
			if (urlParams.has('auth_success')) {
				result.auth_success = urlParams.get('auth_success') === 'true';
			}
			if (urlParams.has('token')) {
				result.token = urlParams.get('token');
			}
			if (urlParams.has('user_id')) {
				result.user_id = urlParams.get('user_id');
			}
			if (urlParams.has('auth_error')) {
				result.auth_error = urlParams.get('auth_error');
			}
			
			// Clear the URL parameters
			if (Object.keys(result).length > 0) {
				window.history.replaceState({}, document.title, window.location.pathname);
			}
			
			return JSON.stringify(result);
		})()
		"""
		
		var result = JavaScriptBridge.eval(js_code)
		if result and result != "{}":
			var json = JSON.new()
			var parse_result = json.parse(result)
			
			if parse_result == OK:
				var params = json.data
				handle_oauth_callback_result(params)

func handle_oauth_callback_result(params: Dictionary):
	"""Handle OAuth callback results from URL parameters"""
	print("OAuth callback parameters detected: ", params)
	
	if params.has("auth_error"):
		var error = params.auth_error
		print("OAuth error: ", error)
		emit_signal("oauth_login_failed", "Authentication failed: " + error)
		return
	
	if params.has("auth_success") and params.auth_success and params.has("token"):
		print("OAuth success! Processing token...")
		
		# Store the OAuth data
		jwt_token = params.token
		current_user_id = params.get("user_id", "")
		current_auth_mode = AuthMode.OAUTH_JWT
		is_authenticated = true
		
		# We'll get the full Google user data when we verify the token
		google_user_data = {}
		
		# Save session and verify token
		save_user_session()
		
		# Verify the token to get user data
		verify_jwt_token()
		
		emit_signal("oauth_login_success", google_user_data)
		emit_signal("authentication_state_changed", true)
		
		print("OAuth login completed successfully!")

# User Session Management
func initialize_user_session():
	"""Load existing user session or create new user"""
	print("Initializing user session...")
	
	# Try to load saved user ID from local storage (Godot equivalent)
	var save_file_path = "user://lifequest_user.save"
	
	if FileAccess.file_exists(save_file_path):
		# Load existing user session
		print("Found existing user session")
		load_user_session(save_file_path)
	else:
		# Create new user
		print("Creating new user...")
		create_new_user()

func load_user_session(file_path: String):
	"""Load user ID from saved file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var saved_data = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(saved_data)
		
		if parse_result == OK and json.data.has("user_id"):
			current_user_id = json.data.user_id
			
			# Load OAuth data if available (new format)
			if json.data.has("jwt_token"):
				jwt_token = json.data.get("jwt_token", "")
			if json.data.has("google_user_data"):
				google_user_data = json.data.get("google_user_data", {})
			if json.data.has("auth_mode"):
				current_auth_mode = json.data.get("auth_mode", AuthMode.LEGACY_USER_ID)
			
			# Set authentication state
			is_authenticated = (jwt_token != "" or current_user_id != "")
			emit_signal("authentication_state_changed", is_authenticated)
			
			print("Loaded user session: ", current_user_id, " (", AuthMode.keys()[current_auth_mode], ")")
			return true
		else:
			print("Invalid save file format")
	
	# Fallback to creating new user
	create_new_user()
	return false

func save_user_session():
	"""Save current user ID to local storage"""
	var save_file_path = "user://lifequest_user.save"
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	
	if file:
		var save_data = {
			"user_id": current_user_id,
			"jwt_token": jwt_token,
			"google_user_data": google_user_data,
			"auth_mode": current_auth_mode,
			"saved_at": Time.get_datetime_string_from_system()
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("User session saved")
		return true
	else:
		print("Failed to save user session")
		return false

func create_new_user():
	"""Generate new unique user ID and create user via API"""
	# Generate unique user ID
	current_user_id = generate_unique_user_id()
	print("Generated new user ID: ", current_user_id)
	
	# TEMPORARY: Skip API user creation (backend doesn't support it yet)
	print("TEMP: Using existing backend user system")
	save_user_session()
	
	# Auto-fetch profile to initialize user
	await get_tree().create_timer(1.0).timeout
	get_user_profile()

func generate_unique_user_id() -> String:
	"""Generate cryptographically unique user ID"""
	var timestamp = int(Time.get_unix_time_from_system())
	var random_bytes = []
	
	# Generate 16 random bytes
	for i in range(16):
		random_bytes.append(randi() % 256)
	
	# Convert to hex string
	var hex_string = ""
	for byte in random_bytes:
		hex_string += "%02x" % byte
	
	return str(timestamp) + "_" + hex_string

# Test API connection
func test_connection():
	print("Testing API connection...")
	_make_request("/health", HTTPClient.METHOD_GET)

# Generate a random quest using our smart algorithm
func generate_quest():
	if current_user_id == "":
		print("No user session - cannot generate quest")
		return
	print("Generating random quest for user: ", current_user_id)
	_make_request("/api/quests/generate", HTTPClient.METHOD_POST)

# Enhanced quest generation with difficulty preferences
func generate_quest_with_difficulty(recommended_difficulties: Array, preferred_category: QuestManager.QuestCategory):
	if current_user_id == "":
		print("No user session - cannot generate quest")
		return
	
	var difficulty_strings = []
	for diff in recommended_difficulties:
		difficulty_strings.append(get_difficulty_string_from_enum(diff))
	
	var request_data = {
		"user_level": QuestManager.get_user_stats()["level"],
		"preferred_difficulties": difficulty_strings,
		"preferred_category": QuestManager.CATEGORY_MAPPING[preferred_category]
	}
	
	print("  Generating level-appropriate quest for user: ", current_user_id)
	print("  Preferred difficulties: ", difficulty_strings)
	print("  Preferred category: ", QuestManager.CATEGORY_MAPPING[preferred_category])
	
	_make_request("/api/quests/generate", HTTPClient.METHOD_POST, request_data)

# Helper function to convert difficulty enum to string
func get_difficulty_string_from_enum(difficulty_enum: QuestManager.QuestDifficulty) -> String:
	for key in QuestManager.DIFFICULTY_MAPPING:
		if QuestManager.DIFFICULTY_MAPPING[key] == difficulty_enum:
			return key
	return "easy"  # fallback

# Complete a quest and earn XP
func complete_quest(quest_id: String):
	if current_user_id == "":
		print("No user session - cannot complete quest")
		return
	print("Completing quest: ", quest_id, " for user: ", current_user_id)
	var endpoint = "/api/quests/" + quest_id + "/complete"
	_make_request(endpoint, HTTPClient.METHOD_POST)

# Get user profile and stats
func get_user_profile():
	if current_user_id == "":
		print("No user session - cannot get profile")
		return
	print("Fetching user profile for: ", current_user_id)
	_make_request("/api/user/profile", HTTPClient.METHOD_GET)

# Get active quests
func get_active_quests():
	if current_user_id == "":
		print("No user session - cannot get active quests")
		return
	print("Fetching active quests for user: ", current_user_id)
	_make_request("/api/quests/active", HTTPClient.METHOD_GET)

# Generic request handler
func _make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}):
	var url = API_BASE_URL + endpoint
	var headers = ["Content-Type: application/json"]
	
	# Add authentication header based on current mode
	if current_auth_mode == AuthMode.OAUTH_JWT and jwt_token != "":
		headers.append("Authorization: Bearer " + jwt_token)
	elif current_auth_mode == AuthMode.LEGACY_USER_ID and current_user_id != "":
		headers.append("X-User-ID: " + current_user_id)
	
	var body = ""
	if data.size() > 0:
		body = JSON.stringify(data)
	
	print("API Request: ", method_to_string(method), " ", endpoint)
	if current_user_id != "":
		print("User ID: ", current_user_id)
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("Request failed with error: ", error)
		emit_signal("api_error", "Failed to make request: " + str(error))

# Handle API responses
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	print("API Response: ", response_code)
	
	if response_code != 200:
		var error_msg = "API returned status: " + str(response_code)
		print(" ", error_msg)
		emit_signal("api_error", error_msg)
		return
	
	# Parse JSON response
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("Failed to parse JSON response")
		emit_signal("api_error", "Invalid JSON response")
		return
	
	var response_data = json.data
	
	if not response_data.has("success"):
		print("Invalid API response format")
		emit_signal("api_error", "Invalid response format")
		return
	
	if not response_data.success:
		var error_msg = response_data.get("error", "Unknown API error")
		print("API Error: ", error_msg)
		emit_signal("api_error", error_msg)
		return
	
	# Success! Route to appropriate handler
	_handle_successful_response(response_data)

# Route successful responses to appropriate signals
func _handle_successful_response(response_data: Dictionary):
	var data = response_data.get("data", {})
	var message = response_data.get("message", "")
	
	print("API Success: ", message)
	
	# Determine response type by checking data structure
	if data.has("id") and data.has("title") and data.has("description"):
		# This is a quest object
		print("Quest received: ", data.title)
		emit_signal("quest_generated", data)
		
	elif data.has("xp_gained"):
		# This is a quest completion result
		print("Quest completed! +", data.xp_gained, " XP")
		if data.get("level_up", false):
			print("LEVEL UP!")
		if data.get("tier_unlocks", []).size() > 0:
			print("New tiers unlocked: ", data.tier_unlocks)
		emit_signal("quest_completed", data)
		
	elif data.has("username") or data.has("current_level"):
		# This is user profile data
		print("Profile updated - Level ", data.get("current_level", 1), ", XP: ", data.get("total_xp", 0))
		emit_signal("profile_updated", data)
		
	elif data.has("user_id") and data.has("created_at"):
		# This is user creation response
		print("User created successfully: ", data.user_id)
		save_user_session()
		emit_signal("user_created", data)
		
		# Auto-fetch profile after user creation
		await get_tree().create_timer(1.0).timeout
		get_user_profile()
		
	elif data.has("auth_url"):
		# This is OAuth login initiation response
		print("OAuth URL received")
		emit_signal("oauth_login_ready", data.auth_url)
		
	elif data.has("token") and data.has("user"):
		# This is OAuth login success response
		print("OAuth login successful!")
		jwt_token = data.token
		google_user_data = data.user
		current_user_id = data.user.get("id", "")
		current_auth_mode = AuthMode.OAUTH_JWT
		is_authenticated = true
		
		save_user_session()
		emit_signal("oauth_login_success", google_user_data)
		emit_signal("authentication_state_changed", true)
		
	elif data.has("valid") and data.get("valid") == true:
		# This is JWT verification success
		print("JWT token verified successfully")
		is_authenticated = true
		emit_signal("authentication_state_changed", true)
		
	elif data.has("valid") and data.get("valid") == false:
		# This is JWT verification failure
		print("JWT token expired or invalid")
		jwt_token = ""
		current_auth_mode = AuthMode.LEGACY_USER_ID
		is_authenticated = false
		save_user_session()
		emit_signal("authentication_state_changed", false)
		
	else:
		# Generic data response
		print("Data received: ", data)

# Helper function to convert method enum to string
func method_to_string(method: HTTPClient.Method) -> String:
	match method:
		HTTPClient.METHOD_GET: return "GET"
		HTTPClient.METHOD_POST: return "POST"
		HTTPClient.METHOD_PUT: return "PUT"
		HTTPClient.METHOD_DELETE: return "DELETE"
		_: return "UNKNOWN"

# Convenience function to test quest generation
func test_quest_flow():
	print("Testing complete quest flow...")
	await get_tree().create_timer(1.0).timeout
	generate_quest()

# Debug function to reset user session (for testing)
func reset_user_session():
	"""Delete saved user session and create new user"""
	print("Resetting user session...")
	var save_file_path = "user://lifequest_user.save"
	
	if FileAccess.file_exists(save_file_path):
		DirAccess.remove_absolute(save_file_path)
		print("Deleted old user session")
	
	current_user_id = ""
	jwt_token = ""
	google_user_data = {}
	current_auth_mode = AuthMode.LEGACY_USER_ID
	is_authenticated = false
	print("Current User ID has been cleared")
	emit_signal("authentication_state_changed", false)
	create_new_user()

# OAuth Authentication Methods
func initiate_google_oauth():
	"""Start Google OAuth flow - gets authorization URL from API"""
	print("Initiating Google OAuth flow...")
	_make_oauth_request("/auth/google/login", HTTPClient.METHOD_GET)

func handle_oauth_callback(code: String, state: String):
	"""Handle OAuth callback with authorization code"""
	print("Handling OAuth callback...")
	var callback_url = "/auth/google/callback?code=" + code + "&state=" + state
	_make_oauth_request(callback_url, HTTPClient.METHOD_GET)

func verify_jwt_token():
	"""Verify stored JWT token is still valid"""
	if jwt_token == "":
		print("No JWT token to verify")
		return false
	print("Verifying JWT token...")
	_make_oauth_request("/auth/verify", HTTPClient.METHOD_POST)

func logout_oauth():
	"""Logout from OAuth session and clear tokens"""
	print("Logging out from OAuth session...")
	if jwt_token != "":
		_make_oauth_request("/auth/logout", HTTPClient.METHOD_POST)
	
	# Clear OAuth data immediately
	jwt_token = ""
	google_user_data = {}
	current_auth_mode = AuthMode.LEGACY_USER_ID
	is_authenticated = false
	save_user_session()
	emit_signal("authentication_state_changed", false)

func check_authentication_status():
	"""Check current authentication state and validate if needed"""
	if current_auth_mode == AuthMode.OAUTH_JWT and jwt_token != "":
		verify_jwt_token()
	elif current_auth_mode == AuthMode.LEGACY_USER_ID and current_user_id != "":
		is_authenticated = true
		emit_signal("authentication_state_changed", true)
	else:
		is_authenticated = false
		emit_signal("authentication_state_changed", false)

# OAuth-specific request handler
func _make_oauth_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}):
	"""Make OAuth-specific API requests with proper authentication headers"""
	var url = API_BASE_URL + endpoint
	var headers = ["Content-Type: application/json"]
	
	# Add JWT Bearer token if available
	if jwt_token != "":
		headers.append("Authorization: Bearer " + jwt_token)
	
	var body = ""
	if data.size() > 0:
		body = JSON.stringify(data)
	
	print("OAuth Request: ", method_to_string(method), " ", endpoint)
	if jwt_token != "":
		print("Using JWT authentication")
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("OAuth request failed with error: ", error)
		emit_signal("oauth_login_failed", "Failed to make request: " + str(error))
