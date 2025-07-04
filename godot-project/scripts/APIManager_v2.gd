# APIManager.gd - Singleton for LifeQuest API Communication
# Handles all communication with our deployed quest generation API

extends Node

# API Configuration
const API_BASE_URL = "https://lifequest-api.wazaqglim.workers.dev"

# User session management
var current_user_id: String = ""

# Signals for UI to listen to
signal quest_generated(quest_data)
signal quest_completed(result)
signal profile_updated(profile_data)
signal api_error(error_message)
signal user_created(user_data)

# HTTP request node
var http_request: HTTPRequest

func _ready():
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("ð® LifeQuest API Manager initialized")
	print("ð¡ API Base URL: ", API_BASE_URL)
	
	# Initialize user session
	initialize_user_session()

# User Session Management
func initialize_user_session():
	"""Load existing user session or create new user"""
	print("ð Initializing user session...")
	
	# Try to load saved user ID from local storage (Godot equivalent)
	var save_file_path = "user://lifequest_user.save"
	
	if FileAccess.file_exists(save_file_path):
		# Load existing user session
		print("ð Found existing user session")
		load_user_session(save_file_path)
	else:
		# Create new user
		print("ð¤ Creating new user...")
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
			print("â Loaded user session: ", current_user_id)
			return true
		else:
			print("â Invalid save file format")
	
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
			"saved_at": Time.get_datetime_string_from_system()
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("ð¾ User session saved")
		return true
	else:
		print("â Failed to save user session")
		return false

func create_new_user():
	"""Generate new unique user ID and create user via API"""
	# Generate unique user ID
	current_user_id = generate_unique_user_id()
	print("ð Generated new user ID: ", current_user_id)
	
	# Create user via API
	var user_data = {
		"user_id": current_user_id,
		"username": "Player_" + current_user_id.substr(0, 8)
	}
	_make_request("/api/user/create", HTTPClient.METHOD_POST, user_data)

func generate_unique_user_id() -> String:
	"""Generate cryptographically unique user ID"""
	var timestamp = str(Time.get_unix_time_from_system())
	var random_bytes = []
	
	# Generate 16 random bytes
	for i in range(16):
		random_bytes.append(randi() % 256)
	
	# Convert to hex string
	var hex_string = ""
	for byte in random_bytes:
		hex_string += "%02x" % byte
	
	return timestamp + "_" + hex_string

# Test API connection
func test_connection():
	print("ð Testing API connection...")
	_make_request("/health", HTTPClient.METHOD_GET)

# Generate a random quest using our smart algorithm
func generate_quest():
	if current_user_id == "":
		print("â No user session - cannot generate quest")
		return
	print("ð² Generating random quest for user: ", current_user_id)
	_make_request("/api/quests/generate", HTTPClient.METHOD_POST)

# Complete a quest and earn XP
func complete_quest(quest_id: String):
	if current_user_id == "":
		print("â No user session - cannot complete quest")
		return
	print("â Completing quest: ", quest_id, " for user: ", current_user_id)
	var endpoint = "/api/quests/" + quest_id + "/complete"
	_make_request(endpoint, HTTPClient.METHOD_POST)

# Get user profile and stats
func get_user_profile():
	if current_user_id == "":
		print("â No user session - cannot get profile")
		return
	print("ð¤ Fetching user profile for: ", current_user_id)
	_make_request("/api/user/profile", HTTPClient.METHOD_GET)

# Get active quests
func get_active_quests():
	if current_user_id == "":
		print("â No user session - cannot get active quests")
		return
	print("ð Fetching active quests for user: ", current_user_id)
	_make_request("/api/quests/active", HTTPClient.METHOD_GET)

# Generic request handler
func _make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}):
	var url = API_BASE_URL + endpoint
	var headers = ["Content-Type: application/json"]
	
	# Add user authentication header
	if current_user_id != "":
		headers.append("X-User-ID: " + current_user_id)
	
	var body = ""
	if data.size() > 0:
		body = JSON.stringify(data)
	
	print("ð¤ API Request: ", method_to_string(method), " ", endpoint)
	if current_user_id != "":
		print("ð User ID: ", current_user_id)
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("â Request failed with error: ", error)
		emit_signal("api_error", "Failed to make request: " + str(error))

# Handle API responses
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("ð¥ API Response: ", response_code)
	
	if response_code != 200:
		var error_msg = "API returned status: " + str(response_code)
		print("â ", error_msg)
		emit_signal("api_error", error_msg)
		return
	
	# Parse JSON response
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("â Failed to parse JSON response")
		emit_signal("api_error", "Invalid JSON response")
		return
	
	var response_data = json.data
	
	if not response_data.has("success"):
		print("â Invalid API response format")
		emit_signal("api_error", "Invalid response format")
		return
	
	if not response_data.success:
		var error_msg = response_data.get("error", "Unknown API error")
		print("â API Error: ", error_msg)
		emit_signal("api_error", error_msg)
		return
	
	# Success! Route to appropriate handler
	_handle_successful_response(response_data)

# Route successful responses to appropriate signals
func _handle_successful_response(response_data: Dictionary):
	var data = response_data.get("data", {})
	var message = response_data.get("message", "")
	
	print("â API Success: ", message)
	
	# Determine response type by checking data structure
	if data.has("id") and data.has("title") and data.has("description"):
		# This is a quest object
		print("ð¯ Quest received: ", data.title)
		emit_signal("quest_generated", data)
		
	elif data.has("xp_gained"):
		# This is a quest completion result
		print("ð Quest completed! +", data.xp_gained, " XP")
		if data.get("level_up", false):
			print("ð LEVEL UP!")
		if data.get("tier_unlocks", []).size() > 0:
			print("ð New tiers unlocked: ", data.tier_unlocks)
		emit_signal("quest_completed", data)
		
	elif data.has("username") or data.has("current_level"):
		# This is user profile data
		print("ð¤ Profile updated - Level ", data.get("current_level", 1), ", XP: ", data.get("total_xp", 0))
		emit_signal("profile_updated", data)
		
	elif data.has("user_id") and data.has("created_at"):
		# This is user creation response
		print("ð¤ User created successfully: ", data.user_id)
		save_user_session()
		emit_signal("user_created", data)
		
		# Auto-fetch profile after user creation
		await get_tree().create_timer(1.0).timeout
		get_user_profile()
		
	else:
		# Generic data response
		print("ð Data received: ", data)

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
	print("ð§ª Testing complete quest flow...")
	await get_tree().create_timer(1.0).timeout
	generate_quest()

# Debug function to reset user session (for testing)
func reset_user_session():
	"""Delete saved user session and create new user"""
	print("ð Resetting user session...")
	var save_file_path = "user://lifequest_user.save"
	
	if FileAccess.file_exists(save_file_path):
		DirAccess.remove_absolute(save_file_path)
		print("ðï¸ Deleted old user session")
	
	current_user_id = ""
	create_new_user()
