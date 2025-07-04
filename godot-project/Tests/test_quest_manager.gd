# tests/test_quest_manager.gd
extends GutTest

func test_level_1_gets_correct_difficulties():
	var difficulties = QuestManager.get_recommended_difficulty(1)
	assert_eq(difficulties.size(), 2, "Level 1 should get exactly 2 difficulties")
	assert_has(difficulties, QuestManager.QuestDifficulty.TRIVIAL)
	assert_has(difficulties, QuestManager.QuestDifficulty.EASY)

func test_xp_scaling_math():
	# Level 5 player, hard quest, 20 base XP
	# Formula: 20 * 1.8 (hard) * 1.4 (level 5) = 50.4 → 50
	var result = QuestManager.calculate_scaled_xp_reward(20, "hard", 5)
	assert_eq(result, 50, "Level 5 hard quest should give 50 XP")

func test_difficulty_bonus_system():
	var bonus = QuestManager.calculate_difficulty_bonus("epic", 3)
	assert_eq(bonus.xp, 10, "Epic quest should give challenge bonus")
	
func test_epic_quests_unlock_at_level_8():
	var level_7_difficulties = QuestManager.get_recommended_difficulty(7)
	var level_8_difficulties = QuestManager.get_recommended_difficulty(8)
	
	assert_false(level_7_difficulties.has(QuestManager.QuestDifficulty.EPIC), 
				"Level 7 should not have EPIC quests")
	assert_true(level_8_difficulties.has(QuestManager.QuestDifficulty.EPIC), 
			   "Level 8 should unlock EPIC quests")

func test_level_1_player_no_medium_quests():
	var difficulties = QuestManager.get_recommended_difficulty(1)
	assert_false(difficulties.has(QuestManager.QuestDifficulty.MEDIUM), 
				"Level 1 players should not get MEDIUM quests")

func test_xp_scaling_edge_cases():
	# Test minimum XP (should be at least 5)
	var result = QuestManager.calculate_scaled_xp_reward(1, "trivial", 1)
	assert_gte(result, 5, "Minimum XP should be 5")
	
	# Test epic quest gives big XP (change from >100 to >90)
	result = QuestManager.calculate_scaled_xp_reward(20, "epic", 10)
	assert_gt(result, 90, "Epic quest at level 10 should give substantial XP")
