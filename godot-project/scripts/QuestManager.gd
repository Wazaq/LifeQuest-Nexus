# QuestManager.gd - Manages quest state and progression
# Bridges between API and UI for quest-related functionality

extends Node

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

# Public interface for getting a new quest
func get_new_quest():
	print("🎲 Requesting new quest from algorithm...")
	APIManager.generate_quest()

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

# Format quest for display
func format_quest_for_display(quest_data: Dictionary) -> Dictionary:
	return {
		"title": quest_data.get("title", "Unknown Quest"),
		"description": quest_data.get("description", "No description"),
		"xp_reward": quest_data.get("xp_reward", 0),
		"category": quest_data.get("category", "unknown"),
		"difficulty": quest_data.get("difficulty", 0),
		"tags": quest_data.get("tags", []),
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
	print("❌ API Error in QuestManager: ", error_message)
	
	# Handle specific error cases
	if "No quests available" in error_message:
		emit_signal("no_quests_available")

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
