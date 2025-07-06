# tests/test_quest_data_loader.gd
extends GutTest

func before_each():
	# Reset the cache before each test to ensure clean state
	QuestDataLoader._data_loaded = false
	QuestDataLoader._categories_cache = {}
	QuestDataLoader._quests_cache = {}

func test_loads_all_quest_categories():
	var categories = QuestDataLoader.get_categories()
	assert_false(categories.is_empty(), "Should load category data")
	
	# Test that we have the expected Maslow categories
	assert_true(categories.has("foundation_realm"), "Should have foundation_realm")
	assert_true(categories.has("safety_sanctum"), "Should have safety_sanctum")
	assert_true(categories.has("connection_crossroads"), "Should have connection_crossroads")

func test_loads_foundation_realm_quests():
	var quests = QuestDataLoader.get_quests_for_category("foundation_realm")
	assert_false(quests.is_empty(), "Foundation realm should have quests")
	
	# Test quest structure
	var first_quest = quests[0]
	assert_true(first_quest.has("id"), "Quest should have ID")
	assert_true(first_quest.has("title"), "Quest should have title")
	assert_true(first_quest.has("description"), "Quest should have description")
	assert_true(first_quest.has("xp_reward"), "Quest should have XP reward")
	assert_true(first_quest.has("difficulty"), "Quest should have difficulty")

func test_caching_works():
	# First call should load data
	var categories1 = QuestDataLoader.get_categories()
	assert_true(QuestDataLoader._data_loaded, "Data should be marked as loaded")
	
	# Second call should use cache
	var categories2 = QuestDataLoader.get_categories()
	assert_eq(categories1.size(), categories2.size(), "Cached data should match")

func test_handles_invalid_category():
	var quests = QuestDataLoader.get_quests_for_category("nonexistent_category")
	assert_true(quests.is_empty(), "Invalid category should return empty array")

func test_available_category_ids():
	var category_ids = QuestDataLoader.get_available_category_ids()
	assert_true(category_ids.size() > 0, "Should have available categories")
	assert_true(category_ids.has("foundation_realm"), "Should include foundation_realm")
	assert_true(category_ids.has("safety_sanctum"), "Should include safety_sanctum")

func test_quest_validation():
	var quests = QuestDataLoader.get_quests_for_category("foundation_realm")
	if quests.size() > 0:
		var quest = quests[0]
		var is_valid = QuestDataLoader.validate_quest_data(quest)
		assert_true(is_valid, "Quest data should be valid")

func test_quest_has_expected_difficulties():
	var quests = QuestDataLoader.get_quests_for_category("foundation_realm")
	var found_difficulties = []
	
	for quest in quests:
		var difficulty = quest.get("difficulty", "")
		if difficulty != "" and not found_difficulties.has(difficulty):
			found_difficulties.append(difficulty)
	
	assert_true(found_difficulties.size() > 0, "Should find quests with difficulties")
	# Check for common difficulties
	var valid_difficulties = ["trivial", "easy", "medium", "hard", "epic"]
	for difficulty in found_difficulties:
		assert_true(valid_difficulties.has(difficulty), 
				   "Difficulty '" + difficulty + "' should be valid")
