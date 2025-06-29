# Main.gd - Main game controller and API testing interface
# Provides a simple UI to test our quest generation API

extends Control

# UI References
@onready var status_label = $VBoxContainer/StatusLabel
@onready var output_label = $VBoxContainer/ScrollContainer/OutputLabel
@onready var test_connection_button = $VBoxContainer/TestConnectionButton
@onready var generate_quest_button = $VBoxContainer/GenerateQuestButton
@onready var complete_quest_button = $VBoxContainer/CompleteQuestButton
@onready var get_profile_button = $VBoxContainer/GetProfileButton

# Current state
var current_quest_data: Dictionary = {}

func _ready():
	print("🎮 LifeQuest Main Scene loaded")
	
	# Connect to Quest Manager signals
	QuestManager.quest_available.connect(_on_quest_available)
	QuestManager.quest_completed_successfully.connect(_on_quest_completed)
	QuestManager.profile_refreshed.connect(_on_profile_refreshed)
	QuestManager.no_quests_available.connect(_on_no_quests_available)
	
	# Connect to API Manager error signal
	APIManager.api_error.connect(_on_api_error)
	
	# Initial UI state
	_update_ui_state()
	
	# Auto-test connection on startup
	await get_tree().create_timer(1.0).timeout
	_test_api_connection()

# Update UI state based on current conditions
func _update_ui_state():
	var has_quest = QuestManager.has_active_quest()
	
	generate_quest_button.disabled = has_quest
	complete_quest_button.disabled = not has_quest
	
	if has_quest:
		var quest = QuestManager.get_current_quest()
		status_label.text = "Quest Active: " + quest.get("title", "Unknown")
	else:
		status_label.text = "Ready for adventure!"

# Button handlers
func _on_test_connection_button_pressed():
	_add_output("[color=yellow]🔍 Testing API connection...[/color]")
	APIManager.test_connection()

func _on_generate_quest_button_pressed():
	_add_output("[color=cyan]🎲 Generating random quest...[/color]")
	QuestManager.get_new_quest()

func _on_complete_quest_button_pressed():
	if not QuestManager.has_active_quest():
		_add_output("[color=red]❌ No active quest to complete![/color]")
		return
	
	var quest = QuestManager.get_current_quest()
	_add_output("[color=green]✅ Completing quest: " + quest.get("title", "Unknown") + "[/color]")
	QuestManager.complete_current_quest()

func _on_get_profile_button_pressed():
	_add_output("[color=purple]👤 Fetching user profile...[/color]")
	QuestManager.refresh_profile()

# Quest Manager signal handlers
func _on_quest_available(quest_data: Dictionary):
	current_quest_data = quest_data
	
	var output = "[color=lime]🎯 NEW QUEST AVAILABLE![/color]\n"
	output += "[b]" + quest_data.get("title", "Unknown Quest") + "[/b]\n"
	output += quest_data.get("description", "No description") + "\n"
	output += "[color=gold]Reward: " + str(quest_data.get("xp_reward", 0)) + " XP[/color]\n"
	output += "Category: " + quest_data.get("category", "unknown") + "\n"
	output += "Difficulty: " + str(quest_data.get("difficulty", 0)) + "\n"
	
	var tags = quest_data.get("tags", [])
	if tags.size() > 0:
		output += "Tags: " + ", ".join(tags) + "\n"
	
	_add_output(output)
	_update_ui_state()

func _on_quest_completed(completion_data: Dictionary):
	var xp_gained = completion_data.get("xp_gained", 0)
	var level_up = completion_data.get("level_up", false)
	var tier_unlocks = completion_data.get("tier_unlocks", [])
	
	var output = "[color=gold]🏆 QUEST COMPLETED![/color]\n"
	output += "XP Gained: +" + str(xp_gained) + "\n"
	
	if level_up:
		output += "[color=yellow]🎉 LEVEL UP![/color]\n"
	
	if tier_unlocks.size() > 0:
		output += "[color=cyan]🔓 New Tiers Unlocked: " + ", ".join(tier_unlocks) + "[/color]\n"
	
	_add_output(output)
	_update_ui_state()

func _on_profile_refreshed(profile_data: Dictionary):
	var level = profile_data.get("current_level", 1)
	var xp = profile_data.get("total_xp", 0)
	var tiers = profile_data.get("unlocked_tiers", ["physiological"])
	
	var output = "[color=purple]👤 PROFILE UPDATED[/color]\n"
	output += "Level: " + str(level) + "\n"
	output += "Total XP: " + str(xp) + "\n"
	output += "Unlocked Tiers: " + ", ".join(tiers) + "\n"
	
	# Calculate progress to next level
	var xp_needed = QuestManager.xp_needed_for_next_level()
	var progress = QuestManager.get_level_progress() * 100
	
	output += "XP to next level: " + str(xp_needed) + "\n"
	output += "Level progress: " + str(int(progress)) + "%\n"
	
	_add_output(output)
	
	# Enable buttons after profile is loaded
	get_profile_button.disabled = false
	if not QuestManager.has_active_quest():
		generate_quest_button.disabled = false

func _on_no_quests_available():
	_add_output("[color=orange]⏰ No quests available - all on cooldown![/color]")

func _on_api_error(error_message: String):
	_add_output("[color=red]❌ API Error: " + error_message + "[/color]")

# Helper function to test API connection
func _test_api_connection():
	status_label.text = "Testing API connection..."
	APIManager.test_connection()
	
	# Wait a moment then enable profile fetch
	await get_tree().create_timer(2.0).timeout
	if get_profile_button.disabled:
		get_profile_button.disabled = false
		# Auto-fetch profile
		QuestManager.refresh_profile()

# Add output to the scrolling text area
func _add_output(text: String):
	var timestamp = Time.get_datetime_string_from_system()
	output_label.text += "\n[color=gray][" + timestamp + "][/color] " + text + "\n"
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll_container = $VBoxContainer/ScrollContainer
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

# Debug function - can be called from anywhere
func debug_test_full_flow():
	print("🧪 Starting full quest flow test...")
	_add_output("[color=yellow]🧪 TESTING FULL QUEST FLOW[/color]")
	
	# Get profile first
	QuestManager.refresh_profile()
	await get_tree().create_timer(2.0).timeout
	
	# Generate quest
	QuestManager.get_new_quest()
	await get_tree().create_timer(2.0).timeout
	
	# Complete quest (if available)
	if QuestManager.has_active_quest():
		QuestManager.complete_current_quest()
		await get_tree().create_timer(2.0).timeout
	
	_add_output("[color=lime]🧪 Test flow completed![/color]")
