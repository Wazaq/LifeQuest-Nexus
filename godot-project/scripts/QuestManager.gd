# QuestManager.gd - Manages quest state and progression
# Bridges between API and UI for quest-related functionality

extends Node

# Quest Category System - Maslow Hierarchy Based
enum QuestCategory {
	PHYSIOLOGICAL,    # Health, nutrition, sleep, exercise
	SAFETY,          # Organization, financial, security
	LOVE_BELONGING,  # Social connections, relationships
	ESTEEM,          # Skills, achievements, recognition  
	SELF_ACTUALIZATION # Creativity, growth, purpose
}
const CATEGORY_MAPPING = {
	QuestCategory.PHYSIOLOGICAL: "foundation_realm",
	QuestCategory.SAFETY: "safety_sanctum",
	QuestCategory.LOVE_BELONGING: "connection_crossroads",
	QuestCategory.ESTEEM: "recognition_ridge",
	QuestCategory.SELF_ACTUALIZATION: "actualization_apex"
}
enum QuestDifficulty {
	TRIVIAL,    # 5-10 minutes, minimal effort
	EASY,       # 10-20 minutes, simple action  
	MEDIUM,     # 20-45 minutes, moderate effort
	HARD,       # 45+ minutes, significant commitment
	EPIC        # Multi-day/week challenges
}
const DIFFICULTY_MAPPING = {
	"trivial": QuestDifficulty.TRIVIAL,
	"easy": QuestDifficulty.EASY, 
	"medium": QuestDifficulty.MEDIUM,
	"hard": QuestDifficulty.HARD,
	"epic": QuestDifficulty.EPIC
}

# Current game state
var current_quest: Dictionary = {}
var user_profile: Dictionary = {}
var active_quests: Array = []

# Signals for UI updates
signal quest_available(quest_data)
signal quest_completed_successfully(completion_data)
signal profile_refreshed(profile_data)
signal no_quests_available()

func _ready():
	print("⚔️ LifeQuest Quest Manager initialized")
	
	# Connect to API Manager signals
	APIManager.quest_generated.connect(_on_quest_generated)
	APIManager.quest_completed.connect(_on_quest_completed)
	APIManager.profile_updated.connect(_on_profile_updated)
	APIManager.api_error.connect(_on_api_error)
	
	# Initialize user profile
	refresh_profile()

# Generate quests from JSON
func generate_local_quest(preferred_category: QuestCategory = QuestCategory.PHYSIOLOGICAL):
	print("🎯 Generating local quest for category: ", CATEGORY_MAPPING[preferred_category])
	
	# Get available categories based on user level
	var available_categories = get_available_categories()
	
	# If preferred category not available, pick random available one
	var category_to_use = preferred_category
	if preferred_category not in available_categories:
		category_to_use = available_categories[randi() % available_categories.size()]
	
	# Get category ID for JSON lookup
	var category_id = CATEGORY_MAPPING[category_to_use]
	
	# Load quests from JSON
	var quests = QuestDataLoader.get_quests_for_category(category_id)
	if quests.is_empty():
		print("❌ No quests found for category: ", category_id)
		emit_signal("no_quests_available")
		return
	
	# NEW: Filter quests by appropriate difficulty
	var user_stats = get_user_stats()
	var recommended_difficulties = get_recommended_difficulty(user_stats["level"])
	var appropriate_quests = filter_quests_by_difficulty(quests, recommended_difficulties)

	# Pick random quest
	var random_quest = appropriate_quests[randi() % appropriate_quests.size()]
	#var random_quest = quests[randi() % quests.size()]
	
	# Create enhanced quest data with category info
	var categories_data = QuestDataLoader.get_categories()
	var category_info = categories_data.get(category_id, {})
	
	var quest_data = {
		"id": "local_" + random_quest.get("id", "") + "_" + str(Time.get_unix_time_from_system()),
		"title": random_quest.get("title", "Unknown Quest"),
		"description": random_quest.get("description", ""),
		"xp_reward": random_quest.get("xp_reward", 10),
		"category": category_id,
		"category_name": category_info.get("name", "Unknown"),
		"category_color": category_info.get("color", "#FFFFFF"),
		"category_icon": category_info.get("icon", "⭐"),
		"difficulty": random_quest.get("difficulty", "easy"),
		"tags": random_quest.get("tags", []),
		"duration": random_quest.get("duration", "Unknown"),
		"is_local": true
	}
	
	# Simulate slight delay like API
	await get_tree().create_timer(0.3).timeout
	
	print("✨ Local quest generated: ", quest_data["title"])
	current_quest = quest_data
	
	var formatted_quest = format_quest_for_display(quest_data)
	emit_signal("quest_available", formatted_quest)

# Get available categories based on user progression
func get_available_categories() -> Array[QuestCategory]:
	var user_stats = get_user_stats()
	var user_level = user_stats["level"]
	var available: Array[QuestCategory] = []
	
	# Always available
	available.append(QuestCategory.PHYSIOLOGICAL)
	
	# Unlock based on level
	if user_level >= 2:
		available.append(QuestCategory.SAFETY)
	if user_level >= 3:
		available.append(QuestCategory.LOVE_BELONGING)
	if user_level >= 5:
		available.append(QuestCategory.ESTEEM)
	if user_level >= 8:
		available.append(QuestCategory.SELF_ACTUALIZATION)
	
	return available

# Enhanced API quest request (now uses unified system)
func get_new_quest_api_first():
	print("🎲 Requesting level-appropriate quest from API...")
	get_level_appropriate_quest()

# Enhanced local fallback with difficulty scaling
func try_local_fallback(preferred_category: QuestCategory = QuestCategory.PHYSIOLOGICAL):
	print("🔄 API failed, trying local quest fallback with difficulty scaling...")
	generate_local_quest(preferred_category)

# Calculate recommended difficulty for user level
func get_recommended_difficulty(user_level: int) -> Array:
	var recommended = []
	
	# Always available
	recommended.append(QuestDifficulty.TRIVIAL)
	recommended.append(QuestDifficulty.EASY)
	
	# Level 3+: Medium challenges
	if user_level >= 3:
		recommended.append(QuestDifficulty.MEDIUM)
	
	# Level 5+: Hard challenges  
	if user_level >= 5:
		recommended.append(QuestDifficulty.HARD)
	
	# Level 8+: Epic challenges
	if user_level >= 8:
		recommended.append(QuestDifficulty.EPIC)
	print('quest recommended:', recommended);
	return recommended

# Filter quests by difficulty levels
func filter_quests_by_difficulty(quests: Array, recommended_difficulties: Array) -> Array:
	var filtered_quests = []
	
	for quest in quests:
		var quest_difficulty_string = quest.get("difficulty", "easy")
		var quest_difficulty_enum = DIFFICULTY_MAPPING.get(quest_difficulty_string, QuestDifficulty.EASY)
		
		# Check if this quest's difficulty is in our recommended list
		if quest_difficulty_enum in recommended_difficulties:
			filtered_quests.append(quest)
	
	# Fallback: if no quests match, return all quests (better than crashing)
	if filtered_quests.is_empty():
		print("⚠️ No quests found for recommended difficulties, returning all quests")
		return quests
	
	return filtered_quests

# Unified quest generation - handles both API and local with difficulty scaling
func get_level_appropriate_quest(preferred_category: QuestCategory = QuestCategory.PHYSIOLOGICAL):
	print("ð¯ Getting level-appropriate quest for category: ", CATEGORY_MAPPING[preferred_category])
	
	var user_stats = get_user_stats()
	var recommended_difficulties = get_recommended_difficulty(user_stats["level"])
	
	print("  User level: ", user_stats["level"])
	print("  Recommended difficulties: ", recommended_difficulties)
	
	# Try API first with difficulty preferences
	APIManager.generate_quest_with_difficulty(recommended_difficulties, preferred_category)

# XP Scaling System - Calculate scaled rewards based on difficulty and level
func calculate_scaled_xp_reward(base_xp: int, quest_difficulty: String, user_level: int) -> int:
	var difficulty_multiplier = get_difficulty_multiplier(quest_difficulty)
	var level_scaling = calculate_level_scaling(user_level)
	
	# Base formula: base_xp * difficulty_multiplier * level_scaling
	var scaled_xp = int(base_xp * difficulty_multiplier * level_scaling)
	
	# Ensure minimum viable rewards
	return max(scaled_xp, 5)

func get_difficulty_multiplier(difficulty: String) -> float:
	match difficulty:
		"trivial": return 0.8
		"easy": return 1.0
		"medium": return 1.3
		"hard": return 1.8
		"epic": return 2.5
		_: return 1.0

func calculate_level_scaling(user_level: int) -> float:
	# Gentle scaling to keep rewards meaningful
	return 1.0 + (user_level - 1) * 0.1

# Bonus reward system for challenging yourself
func calculate_difficulty_bonus(quest_difficulty: String, user_level: int) -> Dictionary:
	var bonus = {"xp": 0, "message": ""}
	
	# Bonus for attempting higher difficulties
	var recommended = get_recommended_difficulty(user_level)
	var quest_diff_enum = DIFFICULTY_MAPPING.get(quest_difficulty, QuestDifficulty.EASY)
	
	# Find highest recommended difficulty
	var max_recommended = QuestDifficulty.TRIVIAL
	for diff in recommended:
		if diff > max_recommended:
			max_recommended = diff
	
	if quest_diff_enum > max_recommended:  # Above recommended
		bonus.xp = 10
		bonus.message = "🌟 Challenge Bonus! (+10 XP for exceeding your comfort zone)"
	
	return bonus

# Difficulty Visual System - Get display data for UI
func get_difficulty_display_data(difficulty: String) -> Dictionary:
	match difficulty:
		"trivial":
			return {
				"icon": "⚡",
				"color": Color.LIGHT_GREEN,
				"label": "Quick Win",
				"description": "5-10 minutes"
			}
		"easy":
			return {
				"icon": "🌱", 
				"color": Color.GREEN,
				"label": "Gentle Growth",
				"description": "10-20 minutes"
			}
		"medium":
			return {
				"icon": "🎯",
				"color": Color.ORANGE,
				"label": "Focused Challenge", 
				"description": "20-45 minutes"
			}
		"hard":
			return {
				"icon": "🔥",
				"color": Color.RED,
				"label": "Major Quest",
				"description": "45+ minutes"
			}
		"epic":
			return {
				"icon": "👑",
				"color": Color.PURPLE,
				"label": "Legendary Challenge",
				"description": "Multi-day journey"
			}
		_:
			return {"icon": "❓", "color": Color.WHITE, "label": "Unknown", "description": ""}

# Level progression status and next unlock info
func get_level_progression_status(user_level: int) -> Dictionary:
	return {
		"current_level": user_level,
		"unlocked_difficulties": get_recommended_difficulty(user_level),
		"next_unlock_level": get_next_difficulty_unlock_level(user_level),
		"progression_message": get_progression_message(user_level)
	}

func get_next_difficulty_unlock_level(user_level: int) -> int:
	if user_level < 3:
		return 3  # Medium unlocks at 3
	elif user_level < 5:
		return 5  # Hard unlocks at 5
	elif user_level < 8:
		return 8  # Epic unlocks at 8
	else:
		return -1  # All unlocked

func get_progression_message(user_level: int) -> String:
	if user_level < 3:
		return "Complete more quests to unlock Medium challenges!"
	elif user_level < 5:
		return "Level 5 unlocks Hard quests with greater rewards!"
	elif user_level < 8:
		return "Level 8 unlocks Epic multi-day challenges!"
	else:
		return "You've mastered all difficulty levels!"

# Public interface for completing current quest
func complete_current_quest():
	if current_quest.is_empty():
		print("❌ No current quest to complete")
		return false
	
	var quest_id = current_quest.get("id", "")
	if quest_id == "":
		print("❌ Current quest has no ID")
		return false
	
	print("✅ Completing quest: ", current_quest.get("title", "Unknown"))
	APIManager.complete_quest(quest_id)
	return true

# Refresh user profile from API
func refresh_profile():
	print("🔄 Refreshing user profile...")
	APIManager.get_user_profile()

# Get current user stats
func get_user_stats() -> Dictionary:
	return {
		"level": user_profile.get("current_level", 1),
		"xp": user_profile.get("total_xp", 0),
		"unlocked_tiers": user_profile.get("unlocked_tiers", ["physiological"])
	}

# Check if user has an active quest
func has_active_quest() -> bool:
	return not current_quest.is_empty()

# Get current quest info
func get_current_quest() -> Dictionary:
	return current_quest

# Enhanced quest formatting with difficulty scaling and visual data
func format_quest_for_display(quest_data: Dictionary) -> Dictionary:
	var difficulty_raw = quest_data.get("difficulty", "easy")
	# Ensure difficulty is always a string (handle legacy numeric values)
	var difficulty = str(difficulty_raw) if typeof(difficulty_raw) != TYPE_STRING else difficulty_raw
	if difficulty == "0":  # Convert old numeric default to string
		difficulty = "easy"
		
	var base_xp = quest_data.get("xp_reward", 0)
	var user_stats = get_user_stats()
	var user_level = user_stats["level"]
	
	# Calculate scaled XP and bonus
	var scaled_xp = calculate_scaled_xp_reward(base_xp, difficulty, user_level)
	var difficulty_bonus = calculate_difficulty_bonus(difficulty, user_level)
	var total_xp = scaled_xp + difficulty_bonus.xp
	
	# Get visual display data
	var display_data = get_difficulty_display_data(difficulty)
	
	return {
		"title": quest_data.get("title", "Unknown Quest"),
		"description": quest_data.get("description", "No description"),
		"xp_reward": total_xp,
		"base_xp": base_xp,
		"scaled_xp": scaled_xp,
		"difficulty_bonus": difficulty_bonus,
		"category": quest_data.get("category", "unknown"),
		"difficulty": difficulty,
		"difficulty_display": display_data,
		"tags": quest_data.get("tags", []),
		"duration": quest_data.get("duration", "Unknown"),
		"is_multi_step": quest_data.get("is_multi_step", false),
		"total_steps": quest_data.get("total_steps", 1)
	}

# Calculate XP needed for next level
func xp_needed_for_next_level() -> int:
	var current_xp = user_profile.get("total_xp", 0)
	var current_level = user_profile.get("current_level", 1)
	var next_level_requirement = current_level * 100  # 100 XP per level
	return max(0, next_level_requirement - current_xp)

# Get progress percentage to next level
func get_level_progress() -> float:
	var current_xp = user_profile.get("total_xp", 0)
	var current_level = user_profile.get("current_level", 1)
	var previous_level_xp = (current_level - 1) * 100
	var next_level_xp = current_level * 100
	
	if next_level_xp <= previous_level_xp:
		return 1.0
	
	var progress = float(current_xp - previous_level_xp) / float(next_level_xp - previous_level_xp)
	return clamp(progress, 0.0, 1.0)

# API Manager signal handlers
func _on_quest_generated(quest_data: Dictionary):
	print("🎯 New quest generated: ", quest_data.get("title", "Unknown"))
	current_quest = quest_data
	
	var formatted_quest = format_quest_for_display(quest_data)
	emit_signal("quest_available", formatted_quest)

func _on_quest_completed(completion_data: Dictionary):
	print("🏆 Quest completed successfully!")
	
	# Clear current quest
	current_quest = {}
	
	# Emit completion signal with rewards info
	emit_signal("quest_completed_successfully", completion_data)
	
	# Refresh profile to get updated XP/level
	refresh_profile()

func _on_profile_updated(profile_data: Dictionary):
	print("👤 Profile updated")
	user_profile = profile_data
	emit_signal("profile_refreshed", profile_data)

func _on_api_error(error_message: String):
	print("❌ API Error: ", error_message)
	
	# Try local quest as fallback
	print("🔄 API failed, falling back to local quests...")
	QuestManager.try_local_fallback()

# Debug function to print current state
func debug_print_state():
	print("\n=== QUEST MANAGER STATE ===")
	print("User Level: ", user_profile.get("current_level", 1))
	print("User XP: ", user_profile.get("total_xp", 0))
	print("XP to next level: ", xp_needed_for_next_level())
	print("Level progress: ", get_level_progress() * 100, "%")
	print("Has active quest: ", has_active_quest())
	if has_active_quest():
		print("Current quest: ", current_quest.get("title", "Unknown"))
	print("Unlocked tiers: ", user_profile.get("unlocked_tiers", []))
	print("============================\n")

# Debug function to test difficulty scaling system
func debug_test_difficulty_scaling():
	print("\n=== DIFFICULTY SCALING TEST ===")
	var user_stats = get_user_stats()
	var user_level = user_stats["level"]
	
	print("Current User Level: ", user_level)
	print("Recommended Difficulties: ", get_recommended_difficulty(user_level))
	
	# Test XP scaling for different difficulties
	var test_difficulties = ["trivial", "easy", "medium", "hard", "epic"]
	var base_xp = 20
	
	print("\nXP Scaling Test (Base XP: ", base_xp, "):")
	for difficulty in test_difficulties:
		var scaled_xp = calculate_scaled_xp_reward(base_xp, difficulty, user_level)
		var bonus = calculate_difficulty_bonus(difficulty, user_level)
		var total_xp = scaled_xp + bonus.xp
		
		var display_data = get_difficulty_display_data(difficulty)
		print("  ", difficulty.to_upper(), " (", display_data.icon, " ", display_data.label, "): ", 
			  scaled_xp, " XP", 
			  (" + " + str(bonus.xp) + " bonus = " + str(total_xp) + " total" if bonus.xp > 0 else ""))
	
	print("\nProgression Status:")
	var progression = get_level_progression_status(user_level)
	print("  ", progression.progression_message)
	if progression.next_unlock_level > 0:
		print("  Next unlock at level: ", progression.next_unlock_level)
	
	print("================================\n")
