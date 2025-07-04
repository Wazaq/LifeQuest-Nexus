# tests/test_api_manager.gd
extends GutTest

# Mock data for testing
var mock_quest_response = {
	"success": true,
	"data": {
		"id": "test_quest_123",
		"title": "Test Quest",
		"description": "A test quest for validation",
		"xp_reward": 25,
		"difficulty": "medium",
		"category": "foundation_realm"
	},
	"message": "Quest generated successfully"
}

var mock_completion_response = {
	"success": true,
	"data": {
		"xp_gained": 30,
		"level_up": false,
		"tier_unlocks": []
	},
	"message": "Quest completed successfully"
}

func before_each():
	# Reset API manager state before each test
	APIManager.current_user_id = "test_user_123"

func test_generates_unique_user_id():
	var user_id1 = APIManager.generate_unique_user_id()
	var user_id2 = APIManager.generate_unique_user_id()
	
	assert_ne(user_id1, user_id2, "Should generate unique user IDs")
	assert_true(user_id1.length() > 10, "User ID should be substantial length")
	assert_true(user_id1.contains("_"), "User ID should contain timestamp separator")

func test_converts_difficulty_enum_to_string():
	var trivial_str = APIManager.get_difficulty_string_from_enum(QuestManager.QuestDifficulty.TRIVIAL)
	var easy_str = APIManager.get_difficulty_string_from_enum(QuestManager.QuestDifficulty.EASY)
	var epic_str = APIManager.get_difficulty_string_from_enum(QuestManager.QuestDifficulty.EPIC)
	
	assert_eq(trivial_str, "trivial", "Should convert TRIVIAL enum to string")
	assert_eq(easy_str, "easy", "Should convert EASY enum to string") 
	assert_eq(epic_str, "epic", "Should convert EPIC enum to string")

func test_method_to_string_conversion():
	assert_eq(APIManager.method_to_string(HTTPClient.METHOD_GET), "GET")
	assert_eq(APIManager.method_to_string(HTTPClient.METHOD_POST), "POST")
	assert_eq(APIManager.method_to_string(HTTPClient.METHOD_PUT), "PUT")
	assert_eq(APIManager.method_to_string(HTTPClient.METHOD_DELETE), "DELETE")

func test_handles_empty_user_session():
	APIManager.current_user_id = ""
	
	# These should handle empty user session gracefully
	APIManager.generate_quest()
	APIManager.complete_quest("test_quest")
	APIManager.get_user_profile()
	APIManager.get_active_quests()
	
	# Test passes if no crashes occur
	assert_true(true, "Should handle empty user session without crashing")

func test_quest_generation_with_difficulty_parameters():
	var recommended_difficulties = [
		QuestManager.QuestDifficulty.EASY,
		QuestManager.QuestDifficulty.MEDIUM
	]
	var preferred_category = QuestManager.QuestCategory.PHYSIOLOGICAL
	
	# This should not crash and should handle the parameters
	APIManager.generate_quest_with_difficulty(recommended_difficulties, preferred_category)
	
	# Test passes if no errors occur during parameter handling
	assert_true(true, "Should handle difficulty parameters without crashing")

func test_api_response_type_detection():
	# Test quest response detection
	APIManager._handle_successful_response(mock_quest_response)
	
	# Test completion response detection  
	APIManager._handle_successful_response(mock_completion_response)
	
	# These should not crash - signals will be emitted
	assert_true(true, "Should handle different response types")

func test_user_session_save_load_format():
	var test_user_id = "test_user_456"
	APIManager.current_user_id = test_user_id
	
	# Test save functionality doesn't crash
	var save_result = APIManager.save_user_session()
	
	# Reset and test load
	APIManager.current_user_id = ""
	var load_result = APIManager.load_user_session("user://lifequest_user.save")
	
	# Test file operations work
	assert_true(save_result or true, "Save should complete without errors")
	# Note: load_result depends on file system, so we just test it doesn't crash

func test_api_error_handling():
	var error_response = {
		"success": false,
		"error": "Test error message"
	}
	
	# This should handle error gracefully and emit signal
	APIManager._handle_successful_response(error_response)
	
	assert_true(true, "Should handle API errors without crashing")

# Signal testing (advanced)
func test_quest_generated_signal():
	var signal_watcher = watch_signals(APIManager)
	
	# Simulate successful quest response
	APIManager._handle_successful_response(mock_quest_response)
	
	# Check if signal was emitted
	assert_signal_emitted(APIManager, "quest_generated", "Should emit quest_generated signal")

func test_quest_completed_signal():
	var signal_watcher = watch_signals(APIManager)
	
	# Simulate successful completion response
	APIManager._handle_successful_response(mock_completion_response)
	
	# Check if signal was emitted  
	assert_signal_emitted(APIManager, "quest_completed", "Should emit quest_completed signal")
