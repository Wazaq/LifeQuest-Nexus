# APIManager.gd - Singleton for LifeQuest API Communication
# Handles all communication with our deployed quest generation API

extends Node

# API Configuration
const API_BASE_URL = "https://lifequest-api.wazaqglim.workers.dev"

# Signals for UI to listen to
signal quest_generated(quest_data)
signal quest_completed(result)
signal profile_updated(profile_data)
signal api_error(error_message)

# HTTP request node
var http_request: HTTPRequest

func _ready():
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("🎮 LifeQuest API Manager initialized")
	print("📡 API Base URL: ", API_BASE_URL)

# Test API connection
func test_connection():
	print("🔍 Testing API connection...")
	_make_request("/health", HTTPClient.METHOD_GET)

# Generate a random quest using our smart algorithm
func generate_quest():
	print("🎲 Generating random quest...")
	_make_request("/api/quests/generate", HTTPClient.METHOD_POST)

# Complete a quest and earn XP
func complete_quest(quest_id: String):
	print("✅ Completing quest: ", quest_id)
	var endpoint = "/api/quests/" + quest_id + "/complete"
	_make_request(endpoint, HTTPClient.METHOD_POST)

# Get user profile and stats
func get_user_profile():
	print("👤 Fetching user profile...")
	_make_request("/api/user/profile", HTTPClient.METHOD_GET)

# Get active quests
func get_active_quests():
	print("📋 Fetching active quests...")
	_make_request("/api/quests/active", HTTPClient.METHOD_GET)

# Generic request handler
func _make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}):
	var url = API_BASE_URL + endpoint
	var headers = ["Content-Type: application/json"]
	
	var body = ""
	if data.size() > 0:
		body = JSON.stringify(data)
	
	print("📤 API Request: ", method_to_string(method), " ", endpoint)
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("❌ Request failed with error: ", error)
		emit_signal("api_error", "Failed to make request: " + str(error))

# Handle API responses
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("📥 API Response: ", response_code)
	
	if response_code != 200:
		var error_msg = "API returned status: " + str(response_code)
		print("❌ ", error_msg)
		emit_signal("api_error", error_msg)
		return
	
	# Parse JSON response
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("❌ Failed to parse JSON response")
		emit_signal("api_error", "Invalid JSON response")
		return
	
	var response_data = json.data
	
	if not response_data.has("success"):
		print("❌ Invalid API response format")
		emit_signal("api_error", "Invalid response format")
		return
	
	if not response_data.success:
		var error_msg = response_data.get("error", "Unknown API error")
		print("❌ API Error: ", error_msg)
		emit_signal("api_error", error_msg)
		return
	
	# Success! Route to appropriate handler
	_handle_successful_response(response_data)

# Route successful responses to appropriate signals
func _handle_successful_response(response_data: Dictionary):
	var data = response_data.get("data", {})
	var message = response_data.get("message", "")
	
	print("✅ API Success: ", message)
	
	# Determine response type by checking data structure
	if data.has("id") and data.has("title") and data.has("description"):
		# This is a quest object
		print("🎯 Quest received: ", data.title)
		emit_signal("quest_generated", data)
		
	elif data.has("xp_gained"):
		# This is a quest completion result
		print("🏆 Quest completed! +", data.xp_gained, " XP")
		if data.get("level_up", false):
			print("🎉 LEVEL UP!")
		if data.get("tier_unlocks", []).size() > 0:
			print("🔓 New tiers unlocked: ", data.tier_unlocks)
		emit_signal("quest_completed", data)
		
	elif data.has("username") or data.has("current_level"):
		# This is user profile data
		print("👤 Profile updated - Level ", data.get("current_level", 1), ", XP: ", data.get("total_xp", 0))
		emit_signal("profile_updated", data)
		
	else:
		# Generic data response
		print("📊 Data received: ", data)

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
	print("🧪 Testing complete quest flow...")
	await get_tree().create_timer(1.0).timeout
	generate_quest()
