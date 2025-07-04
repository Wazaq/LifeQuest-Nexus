extends Control

# UI References - Character Stats
@onready var level_value_label = $MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel/StatsVBox/LevelHBox/LevelValueLabel
@onready var xp_value_label = $MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel/StatsVBox/XPHBox/XPValueLabel
@onready var xp_progress_bar = $MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel/StatsVBox/XPProgressBar

# UI References - User Session
@onready var user_id_value_label = $MainScroll/ProfileContainer/MainVBox/UserSessionPanel/UserVBox/UserIdHBox/UserIdValueLabel
@onready var new_user_button = $MainScroll/ProfileContainer/MainVBox/UserSessionPanel/UserVBox/ButtonsHBox/NewUserButton
@onready var refresh_profile_button = $MainScroll/ProfileContainer/MainVBox/UserSessionPanel/UserVBox/ButtonsHBox/RefreshProfileButton

# UI References - Maslow Progress
@onready var physio_status = $MainScroll/ProfileContainer/MainVBox/MaslowProgressPanel/MaslowVBox/PhysiologicalTier/PhysioStatus
@onready var safety_status = $MainScroll/ProfileContainer/MainVBox/MaslowProgressPanel/MaslowVBox/SafetyTier/SafetyStatus

# UI References - Quest History
@onready var history_container = $MainScroll/ProfileContainer/MainVBox/QuestHistoryPanel/HistoryVBox/HistoryContainer
@onready var no_history_label = $MainScroll/ProfileContainer/MainVBox/QuestHistoryPanel/HistoryVBox/HistoryContainer/NoHistoryLabel

# UI References - Navigation
@onready var back_to_tavern_button = $MainScroll/ProfileContainer/MainVBox/BackToTavernButton

# Current profile data
var current_profile_data: Dictionary = {}

func _ready():
	print("ð¤ Profile Scene initialized")
	
	setup_profile_styling()
	connect_buttons()
	load_user_profile()

func _exit_tree():
	"""Clean up resources when scene is freed"""
	# Disconnect APIManager signals to prevent memory leaks
	if APIManager:
		if APIManager.profile_updated.is_connected(_on_profile_updated):
			APIManager.profile_updated.disconnect(_on_profile_updated)
		if APIManager.user_created.is_connected(_on_user_created):
			APIManager.user_created.disconnect(_on_user_created)
		if APIManager.api_error.is_connected(_on_api_error):
			APIManager.api_error.disconnect(_on_api_error)

func connect_buttons():
	"""Connect button signals"""
	if new_user_button:
		new_user_button.pressed.connect(_on_new_user_button_pressed)
		print("â New User button connected")
	else:
		print("â New User button not found!")
	
	if refresh_profile_button:
		refresh_profile_button.pressed.connect(_on_refresh_profile_button_pressed)
		print("â Refresh Profile button connected")
	else:
		print("â Refresh Profile button not found!")
	
	# Connect navigation button
	if back_to_tavern_button:
		back_to_tavern_button.pressed.connect(_on_back_to_tavern_button_pressed)
		print("â Back to Tavern button connected")
	else:
		print("â Back to Tavern button not found!")
	
	# Connect to APIManager signals
	if APIManager:
		APIManager.profile_updated.connect(_on_profile_updated)
		APIManager.user_created.connect(_on_user_created)
		APIManager.api_error.connect(_on_api_error)
		print("â APIManager signals connected")
	else:
		print("â APIManager not found!")
		show_temporary_message("Warning: API not available - profile features limited")

func load_user_profile():
	"""Load and display current user profile"""
	print("ð Loading user profile...")
	
	# Display current user ID
	if APIManager:
		var user_id = APIManager.current_user_id
		if user_id != "":
			if user_id_value_label:
				# Truncate long user IDs for display
				var display_id = user_id
				if display_id.length() > 20:
					display_id = display_id.left(17) + "..."
				user_id_value_label.text = display_id
		else:
			if user_id_value_label:
				user_id_value_label.text = "No user session"
	
	# Request profile data from API
	if APIManager:
		APIManager.get_user_profile()

func _on_profile_updated(profile_data: Dictionary):
	"""Handle profile data update from API"""
	print("â Profile data received: ", profile_data)
	current_profile_data = profile_data
	update_profile_display()

func _on_user_created(user_data: Dictionary):
	"""Handle new user creation"""
	print("ð New user created: ", user_data.get("user_id", "unknown"))
	
	# Update user ID display
	if user_id_value_label:
		var user_id = user_data.get("user_id", "")
		if user_id.length() > 20:
			user_id = user_id.left(17) + "..."
		user_id_value_label.text = user_id
	
	# Show creation success message
	show_temporary_message("New user created successfully!")
	
	# Auto-refresh profile
	await get_tree().create_timer(1.0).timeout
	load_user_profile()

func _on_api_error(error_message: String):
	"""Handle API errors"""
	print("â API Error: ", error_message)
	show_temporary_message("Error: " + error_message)

func update_profile_display():
	"""Update all profile UI elements with current data"""
	if current_profile_data.is_empty():
		print("â ï¸ No profile data to display")
		return
	
	# Update character stats
	update_character_stats()
	
	# Update Maslow progression
	update_maslow_progress()
	
	# Update quest history
	update_quest_history()

func update_character_stats():
	"""Update character level, XP, and progress"""
	var level = current_profile_data.get("current_level", 1)
	var xp = current_profile_data.get("total_xp", 0)
	
	if level_value_label:
		level_value_label.text = str(level)
	
	if xp_value_label:
		xp_value_label.text = str(xp)
	
	# Calculate XP progress toward next level
	if xp_progress_bar:
		# Simple calculation: each level needs (level * 100) XP
		var current_level_xp = level * 100
		var next_level_xp = (level + 1) * 100
		var progress = 0.0
		
		if next_level_xp > current_level_xp:
			var current_progress = xp - current_level_xp
			var needed_for_next = next_level_xp - current_level_xp
			progress = float(current_progress) / float(needed_for_next)
			progress = clamp(progress, 0.0, 1.0)
		
		xp_progress_bar.value = progress * 100

func update_maslow_progress():
	"""Update Maslow tier progress display"""
	var unlocked_tiers = current_profile_data.get("unlocked_tiers", ["physiological"])
	
	# Update Physiological tier
	if physio_status:
		var completed_count = get_tier_completion_count("physiological")
		if "physiological" in unlocked_tiers:
			physio_status.text = "Unlocked (" + str(completed_count) + " completed)"
		else:
			physio_status.text = "Locked"
	
	# Update Safety tier
	if safety_status:
		var completed_count = get_tier_completion_count("safety")
		if "safety" in unlocked_tiers:
			safety_status.text = "Unlocked (" + str(completed_count) + " completed)"
		else:
			var physio_completed = get_tier_completion_count("physiological")
			safety_status.text = "Locked (Need " + str(max(0, 10 - physio_completed)) + " more Physiological)"

func get_tier_completion_count(tier: String) -> int:
	"""Get number of completed quests for a specific tier"""
	# This would ideally come from the API, but for now we'll estimate
	var tier_progress = current_profile_data.get("tier_progress", {})
	return tier_progress.get(tier, 0)

func update_quest_history():
	"""Update quest history display"""
	# Clear existing history items (except the "no history" label)
	for child in history_container.get_children():
		if child.name != "NoHistoryLabel":
			child.queue_free()
	
	# For now, we'll show a placeholder since quest history isn't in the API yet
	var total_completed = current_profile_data.get("total_quests_completed", 0)
	
	if total_completed > 0:
		if no_history_label:
			no_history_label.visible = false
		
		# Create a summary item
		var summary_label = Label.new()
		summary_label.text = "Total Quests Completed: " + str(total_completed)
		summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_container.add_child(summary_label)
		
		# Add a note about detailed history
		var note_label = Label.new()
		note_label.text = "(Detailed quest history coming soon!)"
		note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_container.add_child(note_label)
	else:
		if no_history_label:
			no_history_label.visible = true

# Button Event Handlers
func _on_new_user_button_pressed():
	"""Handle New User button press"""
	print("ð Creating new user...")
	
	if new_user_button:
		new_user_button.disabled = true
		new_user_button.text = "Creating..."
	
	# Reset user session and create new user
	if APIManager:
		APIManager.reset_user_session()
	
	# Re-enable button after delay
	await get_tree().create_timer(2.0).timeout
	if new_user_button:
		new_user_button.disabled = false
		new_user_button.text = "Create New User"

func _on_refresh_profile_button_pressed():
	"""Handle Refresh Profile button press"""
	print("ð Refreshing profile...")
	
	if refresh_profile_button:
		refresh_profile_button.disabled = true
		refresh_profile_button.text = "Refreshing..."
	
	# Reload profile data
	load_user_profile()
	
	# Re-enable button after delay
	await get_tree().create_timer(1.0).timeout
	if refresh_profile_button:
		refresh_profile_button.disabled = false
		refresh_profile_button.text = "Refresh Profile"

func show_temporary_message(message: String):
	"""Show a temporary message to the user"""
	print("ð¢ Profile Message: ", message)
	# For now, just log. Later we could add a notification system

func setup_profile_styling():
	"""Apply consistent styling to match tavern theme"""
	
	# Main profile container styling
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color("#2F4F4F")  # Dark slate gray
	main_style.corner_radius_bottom_left = 15
	main_style.corner_radius_bottom_right = 15
	main_style.corner_radius_top_left = 15
	main_style.corner_radius_top_right = 15
	main_style.border_width_bottom = 2
	main_style.border_width_top = 2
	main_style.border_width_left = 2
	main_style.border_width_right = 2
	main_style.border_color = Color("#DAA520")  # Goldenrod border
	main_style.content_margin_left = 20
	main_style.content_margin_right = 20
	main_style.content_margin_top = 20
	main_style.content_margin_bottom = 20
	
	var profile_container = $MainScroll/ProfileContainer
	if profile_container:
		profile_container.add_theme_stylebox_override("panel", main_style)
	
	# Character stats panel styling
	setup_panel_style($MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel, "#3D2914")
	
	# User session panel styling
	setup_panel_style($MainScroll/ProfileContainer/MainVBox/UserSessionPanel, "#5D4037")
	
	# Maslow progress panel styling
	setup_panel_style($MainScroll/ProfileContainer/MainVBox/MaslowProgressPanel, "#3D2914")
	
	# Quest history panel styling
	setup_panel_style($MainScroll/ProfileContainer/MainVBox/QuestHistoryPanel, "#5D4037")
	
	# Text colors
	setup_text_colors()
	
	# Button styles
	setup_button_styles()

func setup_panel_style(panel_node, bg_color: String):
	"""Apply consistent panel styling"""
	if not panel_node:
		return
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(bg_color)
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.border_width_bottom = 1
	panel_style.border_width_top = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_color = Color("#8B4513")  # Saddle brown border
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	
	panel_node.add_theme_stylebox_override("panel", panel_style)

func setup_text_colors():
	"""Apply consistent text colors"""
	
	# Title styling
	var title = $MainScroll/ProfileContainer/MainVBox/HeaderSection/TitleLabel
	if title:
		title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
	
	var subtitle = $MainScroll/ProfileContainer/MainVBox/HeaderSection/SubtitleLabel
	if subtitle:
		subtitle.add_theme_color_override("font_color", Color("#CD853F"))  # Peru
	
	# Section titles
	var stats_title = $MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel/StatsVBox/StatsTitle
	if stats_title:
		stats_title.add_theme_color_override("font_color", Color("#DAA520"))
	
	var user_title = $MainScroll/ProfileContainer/MainVBox/UserSessionPanel/UserVBox/UserTitle
	if user_title:
		user_title.add_theme_color_override("font_color", Color("#DAA520"))
	
	var maslow_title = $MainScroll/ProfileContainer/MainVBox/MaslowProgressPanel/MaslowVBox/MaslowTitle
	if maslow_title:
		maslow_title.add_theme_color_override("font_color", Color("#DAA520"))
	
	var history_title = $MainScroll/ProfileContainer/MainVBox/QuestHistoryPanel/HistoryVBox/HistoryTitle
	if history_title:
		history_title.add_theme_color_override("font_color", Color("#DAA520"))
	
	# Stats labels
	var level_label = $MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel/StatsVBox/LevelHBox/LevelLabel
	if level_label:
		level_label.add_theme_color_override("font_color", Color("#DAA520"))
	
	var xp_label = $MainScroll/ProfileContainer/MainVBox/CharacterStatsPanel/StatsVBox/XPHBox/XPLabel
	if xp_label:
		xp_label.add_theme_color_override("font_color", Color("#DAA520"))
	
	# User session labels
	var user_id_label = $MainScroll/ProfileContainer/MainVBox/UserSessionPanel/UserVBox/UserIdHBox/UserIdLabel
	if user_id_label:
		user_id_label.add_theme_color_override("font_color", Color("#DAA520"))
	
	# Maslow tier labels
	var physio_label = $MainScroll/ProfileContainer/MainVBox/MaslowProgressPanel/MaslowVBox/PhysiologicalTier/PhysioLabel
	if physio_label:
		physio_label.add_theme_color_override("font_color", Color("#32CD32"))  # Green (unlocked)
	
	var safety_label = $MainScroll/ProfileContainer/MainVBox/MaslowProgressPanel/MaslowVBox/SafetyTier/SafetyLabel
	if safety_label:
		safety_label.add_theme_color_override("font_color", Color("#CD853F"))  # Peru (locked)

func setup_button_styles():
	"""Apply consistent button styling"""
	
	if new_user_button:
		apply_button_style(new_user_button, "#DAA520", "#FFD700")  # Gold
	
	if refresh_profile_button:
		apply_button_style(refresh_profile_button, "#32CD32", "#00FF00")  # Green

func apply_button_style(button: Button, normal_color: String, hover_color: String):
	"""Apply styling to a button"""
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(normal_color)
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(hover_color)
	button_hover.corner_radius_bottom_left = 8
	button_hover.corner_radius_bottom_right = 8
	button_hover.corner_radius_top_left = 8
	button_hover.corner_radius_top_right = 8
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_hover)
	button.add_theme_color_override("font_color", Color("#2F4F4F"))  # Dark text

# Navigation Event Handler
func _on_back_to_tavern_button_pressed():
	"""Handle Back to Tavern button press"""
	print("ð° Returning to Tavern...")
	get_tree().change_scene_to_file("res://scenes/TavernMain.tscn")
