# Tests/integration/test_new_player_setup.gd
# Integration test for complete new player setup flow
extends GutTest

# Test data
var test_save_path = "user://test_lifequest_user.save"
var original_user_id: String

func before_each():
	"""Set up clean test environment"""
	# Store original user ID to restore later
	original_user_id = APIManager.current_user_id
	
	# Clean up any test save files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	
	# Reset APIManager state
	APIManager.current_user_id = ""

func after_each():
	"""Clean up after each test"""
	# Clean up test files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	
	# Restore original user state
	APIManager.current_user_id = original_user_id
	
	# Force garbage collection to clean up orphans
	await get_tree().process_frame

func test_new_player_complete_setup_flow():
	"""Test the complete new player setup from start to finish"""
	
	# Step 1: Verify clean state
	assert_eq(APIManager.current_user_id, "", "Should start with no user ID")
	assert_false(FileAccess.file_exists(test_save_path), "Should have no saved user file")
	
	# Step 2: Simulate new player setup
	var signal_watcher = watch_signals(APIManager)
	
	# Create new user (simulating first game launch)
	APIManager.create_new_user()
	
	# Verify user ID was generated
	assert_ne(APIManager.current_user_id, "", "Should generate user ID")
	assert_true(APIManager.current_user_id.length() > 10, "User ID should be substantial")
	assert_true(APIManager.current_user_id.contains("_"), "User ID should have timestamp format")
	
	# Step 3: Test user session persistence
	var save_success = APIManager.save_user_session()
	assert_true(save_success, "Should save user session successfully")
	
	# Step 4: Simulate game restart - load existing user
	var generated_user_id = APIManager.current_user_id
	APIManager.current_user_id = ""  # Reset to simulate restart
	
	var load_success = APIManager.load_user_session("user://lifequest_user.save")
	assert_eq(APIManager.current_user_id, generated_user_id, "Should load same user ID after restart")

func test_user_id_generation_uniqueness():
	"""Test that user ID generation produces unique values"""
	
	var user_ids = []
	
	# Generate multiple user IDs
	for i in range(5):
		var new_id = APIManager.generate_unique_user_id()
		assert_false(new_id in user_ids, "Each user ID should be unique")
		user_ids.append(new_id)
		
		# Small delay to ensure timestamp differences
		await get_tree().create_timer(0.01).timeout
	
	# Verify all IDs follow expected format
	for user_id in user_ids:
		assert_true(user_id.contains("_"), "User ID should contain timestamp separator")
		var parts = user_id.split("_")
		assert_eq(parts.size(), 2, "User ID should have timestamp and random parts")
		assert_true(parts[0].is_valid_int(), "First part should be timestamp")
		assert_eq(parts[1].length(), 32, "Random part should be 32 hex characters")

func test_new_player_default_state():
	"""Test that new players start with appropriate default values"""
	
	# Create new user
	APIManager.create_new_user()
	
	# Check user session state
	assert_ne(APIManager.current_user_id, "", "New player should have user ID")
	
	# Note: We can't test profile values directly since they come from API
	# But we can test that the APIManager is ready to request profile data
	var can_request_profile = APIManager.current_user_id != ""
	assert_true(can_request_profile, "Should be able to request profile for new user")

func test_user_session_reset_functionality():
	"""Test the reset user session feature works correctly"""
	
	# Set up existing user session
	APIManager.current_user_id = "existing_user_123"
	APIManager.save_user_session()
	
	var signal_watcher = watch_signals(APIManager)
	
	# Reset user session
	APIManager.reset_user_session()
	
	# Verify reset worked
	assert_ne(APIManager.current_user_id, "existing_user_123", "Should have new user ID after reset")
	assert_ne(APIManager.current_user_id, "", "Should have generated new user ID")

func test_save_file_format_validation():
	"""Test that save file contains expected data structure"""
	
	# Create user and save
	APIManager.create_new_user()
	var test_user_id = APIManager.current_user_id
	APIManager.save_user_session()
	
	# Read save file directly and validate format
	var save_file = FileAccess.open("user://lifequest_user.save", FileAccess.READ)
	assert_ne(save_file, null, "Save file should exist and be readable")
	
	var save_content = save_file.get_as_text()
	save_file.close()
	
	# Parse JSON and validate structure
	var json = JSON.new()
	var parse_result = json.parse(save_content)
	assert_eq(parse_result, OK, "Save file should contain valid JSON")
	
	var save_data = json.data
	assert_true(save_data.has("user_id"), "Save data should contain user_id")
	assert_true(save_data.has("saved_at"), "Save data should contain saved_at timestamp")
	assert_eq(save_data.user_id, test_user_id, "Saved user_id should match current user")

func test_initialize_user_session_flow():
	"""Test the complete initialize_user_session logic"""
	
	# Test Case 1: No existing save file (new player)
	assert_false(FileAccess.file_exists(test_save_path), "Should start without save file")
	
	APIManager.initialize_user_session()
	await get_tree().create_timer(0.1).timeout  # Allow initialization to complete
	
	assert_ne(APIManager.current_user_id, "", "Should create new user when no save exists")
	
	# Test Case 2: Existing save file (returning player)
	var first_user_id = APIManager.current_user_id
	
	# Simulate restart
	APIManager.current_user_id = ""
	APIManager.initialize_user_session()
	await get_tree().create_timer(0.1).timeout
	
	assert_eq(APIManager.current_user_id, first_user_id, "Should load existing user on restart")

func test_error_handling_corrupted_save():
	"""Test handling of corrupted save files"""
	
	# Create corrupted save file
	var corrupted_file = FileAccess.open("user://lifequest_user.save", FileAccess.WRITE)
	corrupted_file.store_string("{ invalid json content")
	corrupted_file.close()
	
	# Initialize should handle corrupted file gracefully
	APIManager.initialize_user_session()
	await get_tree().create_timer(0.1).timeout
	
	# Should create new user instead of crashing
	assert_ne(APIManager.current_user_id, "", "Should create new user when save is corrupted")
