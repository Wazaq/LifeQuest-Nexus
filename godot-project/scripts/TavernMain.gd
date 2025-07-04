class_name TavernMain
extends Control

# UI References - Using proper node paths instead of unique names
@onready var generate_quest_button: Button = $MainScroll/TavernContainer/MainVBox/QuestBoardSection/GenerateQuestButton
@onready var no_quests_label: Label = $MainScroll/TavernContainer/MainVBox/QuestBoardSection/ActiveQuestsContainer/NoQuestsLabel
@onready var active_quests_container: VBoxContainer = $MainScroll/TavernContainer/MainVBox/QuestBoardSection/ActiveQuestsContainer
@onready var level_value_label: Label = $MainScroll/TavernContainer/MainVBox/CharacterStatsPanel/StatsVBox/LevelHBox/LevelValueLabel
@onready var xp_value_label: Label = $MainScroll/TavernContainer/MainVBox/CharacterStatsPanel/StatsVBox/XPHBox/XPValueLabel
@onready var xp_progress_bar: ProgressBar = $MainScroll/TavernContainer/MainVBox/CharacterStatsPanel/StatsVBox/XPProgressBar

# Top Navigation UI References (primary navigation)
@onready var top_profile_button: Button = $MainScroll/TavernContainer/MainVBox/TopNavigationBar/TopProfileButton
@onready var top_tavern_button: Button = $MainScroll/TavernContainer/MainVBox/TopNavigationBar/TopTavernButton

# Current quest state with proper validation
var active_quest_data: Dictionary = {}
var _quest_timeout_timer: Timer = null

# UI state signals for better error handling (removed unused ones)
# Note: Removed unused signals and variables to clean up warnings

func _ready():
	print("🏰 Tavern Main initialized")
	
	setup_tavern_styling()
	connect_quest_system()
	update_user_interface()

func connect_quest_system():
	"""Connect to the QuestManager signals and button events"""
	
	# Connect navigation buttons first
	connect_navigation_buttons()
	
	# Connect generate quest button
	if generate_quest_button:
		generate_quest_button.pressed.connect(_on_generate_quest_pressed)
		print("✅ Generate Quest button connected")
	else:
		print("❌ Generate Quest button not found!")
	
	# Connect feedback buttons
	var feedback_button = $MainScroll/TavernContainer/MainVBox/FeedbackSection/FeedbackVBox/ButtonsHBox/FeedbackFormButton
	var discord_button = $MainScroll/TavernContainer/MainVBox/FeedbackSection/FeedbackVBox/ButtonsHBox/DiscordButton
	
	if feedback_button:
		feedback_button.pressed.connect(_on_feedback_button_pressed)
		print("✅ Feedback button connected")
	
	if discord_button:
		discord_button.pressed.connect(_on_discord_button_pressed)
		print("✅ Discord button connected")
	
	# Connect to QuestManager signals
	if QuestManager:
		QuestManager.quest_available.connect(_on_quest_available)
		QuestManager.quest_completed_successfully.connect(_on_quest_completed)
		QuestManager.profile_refreshed.connect(_on_profile_refreshed)
		QuestManager.no_quests_available.connect(_on_no_quests_available)
		print("✅ QuestManager signals connected")
	else:
		print("❌ QuestManager not found!")

func update_user_interface():
	"""Update the UI with current user data"""
	var stats = QuestManager.get_user_stats()
	
	# Update character stats display
	if level_value_label:
		level_value_label.text = str(stats.level)
	
	if xp_value_label:
		xp_value_label.text = str(stats.xp)
	
	# Update XP progress bar
	if xp_progress_bar:
		var progress = QuestManager.get_level_progress()
		xp_progress_bar.value = progress * 100
	
	# Check if user has active quest
	if QuestManager.has_active_quest():
		display_active_quest()
	else:
		show_no_active_quests()

func display_active_quest():
	"""Display the current active quest with details and complete button"""
	var quest = QuestManager.get_current_quest()
	if quest.is_empty():
		show_no_active_quests()
		return
	
	# Hide "no quests" label
	if no_quests_label:
		no_quests_label.visible = false
	
	# Clear existing quest UI elements
	clear_quest_display()
	
	# Create quest details container
	create_quest_ui(quest)

func show_no_active_quests():
	"""Show the default 'no active quests' message"""
	clear_quest_display()
	
	if no_quests_label:
		no_quests_label.text = "No active quests. Generate your first adventure above!"
		no_quests_label.visible = true

func clear_quest_display():
	"""Clear any existing quest UI elements"""
	# Safety check - make sure container exists
	if not active_quests_container:
		print("â ï¸ Active quests container not found")
		return
	
	# Remove any previously created quest UI nodes
	for child in active_quests_container.get_children():
		if child.name.begins_with("QuestUI_"):
			child.queue_free()

func create_quest_ui(quest_data: Dictionary):
	"""Create detailed quest UI with completion button"""
	
	# Safety check - make sure container exists
	if not active_quests_container:
		print("â ï¸ Cannot create quest UI - container not found")
		return
	
	# Create main quest panel
	var quest_panel = PanelContainer.new()
	quest_panel.name = "QuestUI_Panel"
	
	# Style the quest panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#3D2914")  # Dark brown
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.border_width_left = 3
	panel_style.border_color = Color("#DAA520")  # Golden border
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	quest_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create quest content container
	var quest_vbox = VBoxContainer.new()
	quest_vbox.name = "QuestUI_VBox"
	quest_panel.add_child(quest_vbox)
	
	# Quest title
	var title_label = Label.new()
	title_label.name = "QuestUI_Title"
	title_label.text = quest_data.get("title", "Unknown Quest")
	title_label.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
	title_label.add_theme_font_size_override("font_size", 18)
	quest_vbox.add_child(title_label)
	
	# Quest description
	var desc_label = RichTextLabel.new()
	desc_label.name = "QuestUI_Description"
	desc_label.text = quest_data.get("description", "No description available")
	desc_label.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat
	desc_label.fit_content = true
	desc_label.custom_minimum_size.y = 60
	quest_vbox.add_child(desc_label)
	
	# Quest info (XP, category, etc.)
	var info_hbox = HBoxContainer.new()
	quest_vbox.add_child(info_hbox)
	
	var xp_label = Label.new()
	xp_label.text = "Reward: " + str(quest_data.get("xp_reward", 0)) + " XP"
	xp_label.add_theme_color_override("font_color", Color("#32CD32"))  # Lime green
	info_hbox.add_child(xp_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(spacer)
	
	var category_label = Label.new()
	category_label.text = quest_data.get("category", "unknown").capitalize()
	category_label.add_theme_color_override("font_color", Color("#CD853F"))  # Peru
	info_hbox.add_child(category_label)
	
	# Complete Quest button
	var complete_button = Button.new()
	complete_button.name = "QuestUI_CompleteButton"
	complete_button.text = "Complete Quest"
	
	# Style the complete button
	var complete_style = StyleBoxFlat.new()
	complete_style.bg_color = Color("#32CD32")  # Lime green
	complete_style.corner_radius_bottom_left = 6
	complete_style.corner_radius_bottom_right = 6
	complete_style.corner_radius_top_left = 6
	complete_style.corner_radius_top_right = 6
	
	var complete_hover = StyleBoxFlat.new()
	complete_hover.bg_color = Color("#00FF00")  # Bright green
	complete_hover.corner_radius_bottom_left = 6
	complete_hover.corner_radius_bottom_right = 6
	complete_hover.corner_radius_top_left = 6
	complete_hover.corner_radius_top_right = 6
	
	complete_button.add_theme_stylebox_override("normal", complete_style)
	complete_button.add_theme_stylebox_override("hover", complete_hover)
	complete_button.add_theme_color_override("font_color", Color("#2F4F4F"))  # Dark text
	
	# Connect complete button
	complete_button.pressed.connect(_on_complete_quest_pressed)
	
	quest_vbox.add_child(complete_button)
	
	# Add quest panel to container
	active_quests_container.add_child(quest_panel)

func _on_complete_quest_pressed():
	"""Handle complete quest button press"""
	print("✅ Complete Quest button pressed!")
	
	# Complete the current quest
	var success = QuestManager.complete_current_quest()
	if success:
		print("🎉 Quest completion initiated!")
	else:
		print("❌ Failed to complete quest")

func _on_feedback_button_pressed():
	"""Handle feedback form button press"""
	print("📝 Opening feedback form...")
	OS.shell_open("https://forms.gle/tpgCUKuEh9aTbk9x9")

func _on_discord_button_pressed():
	"""Handle Discord button press"""
	print("💬 Opening Discord...")
	OS.shell_open("https://discord.gg/zxy7EduTYA")

func show_temporary_message(message: String):
	"""Show a temporary message to the user"""
	# This could be enhanced with a proper notification system
	print("📢 User Message: ", message)

# Button Event Handlers
func _on_generate_quest_pressed():
	"""Handle generate quest button press"""
	print("🎲 Generate Quest button pressed!")
	
	# Check if user already has an active quest
	if QuestManager.has_active_quest():
		print("⚠️ User already has an active quest!")
		show_temporary_message("Complete your current quest before generating a new one!")
		return
	
	# Disable button temporarily to prevent spam
	if generate_quest_button:
		generate_quest_button.disabled = true
		generate_quest_button.text = "Generating..."
	
	# Set up timeout timer for quest generation
	cleanup_quest_timer()  # Clean up any existing timer
	_quest_timeout_timer = Timer.new()
	_quest_timeout_timer.wait_time = 10.0  # 10 second timeout
	_quest_timeout_timer.one_shot = true
	_quest_timeout_timer.timeout.connect(_on_quest_timeout)
	add_child(_quest_timeout_timer)
	_quest_timeout_timer.start()
	
	print("🌐 Trying API quest generation...")
	QuestManager.get_new_quest_api_first()
	
	# Request new quest from QuestManager
	#QuestManager.get_new_quest()

func cleanup_quest_timer():
	"""Clean up quest timeout timer properly"""
	if _quest_timeout_timer and is_instance_valid(_quest_timeout_timer):
		_quest_timeout_timer.queue_free()
		_quest_timeout_timer = null

func _exit_tree():
	"""Clean up resources when scene is freed"""
	cleanup_quest_timer()

func _on_quest_timeout():
	"""Handle quest generation timeout"""
	print("â° Quest generation timed out!")
	
	# Re-enable the button
	if generate_quest_button:
		generate_quest_button.disabled = false
		generate_quest_button.text = "Generate New Quest"
	
	# Clean up the timer
	cleanup_quest_timer()
	
	# Show user feedback
	show_temporary_message("Quest generation timed out. Please try again!")

# QuestManager Signal Handlers
func _on_quest_available(quest_data: Dictionary):
	"""Handle new quest generated"""
	cleanup_quest_timer()
	print("🎯 New quest available: ", quest_data.get("title", "Unknown"))
	
	# Store quest data
	active_quest_data = quest_data
	
	# Re-enable generate button
	if generate_quest_button:
		generate_quest_button.disabled = false
		generate_quest_button.text = "Generate New Quest"
	
	# Clear any existing quest displays first
	clear_quest_display()
	
	# Update UI to show new quest
	display_active_quest()
	
	# Show celebration or notification
	show_quest_generated_feedback(quest_data)

func _on_quest_completed(completion_data: Dictionary):
	"""Handle quest completion"""
	print("🏆 Quest completed! XP gained: ", completion_data.get("xp_gained", 0))
	
	# Clear active quest
	active_quest_data = {}
	
	# Clear quest display immediately
	clear_quest_display()
	show_no_active_quests()
	
	# Update UI with new stats
	update_user_interface()
	
	# Show completion celebration
	show_quest_completion_feedback(completion_data)

func _on_profile_refreshed(profile_data: Dictionary):
	"""Handle profile data update"""
	print("👤 Profile refreshed - Level: ", profile_data.get("current_level", 1))
	
	# Update character stats display
	update_user_interface()

func _on_no_quests_available():
	"""Handle case when no quests are available"""
	print("⏰ No quests available - all on cooldown")
	
	# Re-enable button with helpful text
	if generate_quest_button:
		generate_quest_button.disabled = false
		generate_quest_button.text = "All Quests On Cooldown"
	
	# Show helpful feedback
	show_temporary_message("All quests are on cooldown! Come back later for new adventures!")
	
	# Update the no quests label with cooldown info
	if no_quests_label:
		no_quests_label.text = "All quests completed recently! Return later for new adventures."
		no_quests_label.visible = true

# Feedback Functions
func show_quest_generated_feedback(quest_data: Dictionary):
	"""Show visual feedback when quest is generated"""
	# For now, just log. Later we can add particles, sounds, etc.
	print("✨ Quest Generated: ", quest_data.get("title", "Unknown"))
	print("📝 Description: ", quest_data.get("description", "No description"))
	print("🎖️ XP Reward: ", quest_data.get("xp_reward", 0))

func show_quest_completion_feedback(completion_data: Dictionary):
	"""Show visual feedback when quest is completed"""
	# For now, just log. Later we can add celebration animations
	print("🎉 QUEST COMPLETED!")
	print("⚡ XP Gained: +", completion_data.get("xp_gained", 0))
	
	if completion_data.get("level_up", false):
		print("🚀 LEVEL UP!")
	
	var tier_unlocks = completion_data.get("tier_unlocks", [])
	if tier_unlocks.size() > 0:
		print("🔓 New tiers unlocked: ", tier_unlocks)

func show_no_quests_feedback():
	"""Show feedback when no quests are available"""
	print("⏰ All quests are on cooldown. Try again later!")

func setup_tavern_styling():
	# Set the main background gradient
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color("#2F4F4F")  # Dark slate gray base
	main_style.corner_radius_bottom_left = 15
	main_style.corner_radius_bottom_right = 15
	main_style.corner_radius_top_left = 15
	main_style.corner_radius_top_right = 15
	main_style.border_width_bottom = 2
	main_style.border_width_top = 2
	main_style.border_width_left = 2
	main_style.border_width_right = 2
	main_style.border_color = Color("#DAA520")  # Goldenrod border
	
	# Apply to main tavern container
	var tavern_container = $MainScroll/TavernContainer
	tavern_container.add_theme_stylebox_override("panel", main_style)
	
	# Add padding to the main content area
	main_style.content_margin_left = 20
	main_style.content_margin_right = 20
	main_style.content_margin_top = 20
	main_style.content_margin_bottom = 20
	
	# Style the character stats panel
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color("#3D2914")  # Dark brown
	stats_style.corner_radius_bottom_left = 10
	stats_style.corner_radius_bottom_right = 10
	stats_style.corner_radius_top_left = 10
	stats_style.corner_radius_top_right = 10
	stats_style.border_width_bottom = 1
	stats_style.border_width_top = 1
	stats_style.border_width_left = 1
	stats_style.border_width_right = 1
	stats_style.border_color = Color("#8B4513")  # Saddle brown border
	stats_style.content_margin_left = 15
	stats_style.content_margin_right = 15
	stats_style.content_margin_top = 15
	stats_style.content_margin_bottom = 15
	
	var stats_panel = $MainScroll/TavernContainer/MainVBox/CharacterStatsPanel
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	
	# Style Dorin's section
	var dorin_style = StyleBoxFlat.new()
	dorin_style.bg_color = Color("#5D4037")  # Brown
	dorin_style.corner_radius_bottom_left = 10
	dorin_style.corner_radius_bottom_right = 10
	dorin_style.corner_radius_top_left = 10
	dorin_style.corner_radius_top_right = 10
	dorin_style.border_width_left = 4
	dorin_style.border_color = Color("#DAA520")  # Golden left border
	dorin_style.content_margin_left = 15
	dorin_style.content_margin_right = 15
	dorin_style.content_margin_top = 15
	dorin_style.content_margin_bottom = 15
	
	var dorin_panel = $MainScroll/TavernContainer/MainVBox/DorinSection
	dorin_panel.add_theme_stylebox_override("panel", dorin_style)
	
	# Style Maslow section
	var maslow_style = StyleBoxFlat.new()
	maslow_style.bg_color = Color("#3D2914")  # Dark brown
	maslow_style.corner_radius_bottom_left = 8
	maslow_style.corner_radius_bottom_right = 8
	maslow_style.corner_radius_top_left = 8
	maslow_style.corner_radius_top_right = 8
	maslow_style.content_margin_left = 10
	maslow_style.content_margin_right = 10
	maslow_style.content_margin_top = 10
	maslow_style.content_margin_bottom = 10
	
	var maslow_panel = $MainScroll/TavernContainer/MainVBox/MaslowSection
	maslow_panel.add_theme_stylebox_override("panel", maslow_style)
	
	# Style feedback section
	var feedback_style = StyleBoxFlat.new()
	feedback_style.bg_color = Color("#5D4037", 0.3)  # Semi-transparent brown
	feedback_style.corner_radius_bottom_left = 10
	feedback_style.corner_radius_bottom_right = 10
	feedback_style.corner_radius_top_left = 10
	feedback_style.corner_radius_top_right = 10
	feedback_style.border_width_bottom = 1
	feedback_style.border_width_top = 1
	feedback_style.border_width_left = 1
	feedback_style.border_width_right = 1
	feedback_style.border_color = Color("#8B4513")
	feedback_style.content_margin_left = 15
	feedback_style.content_margin_right = 15
	feedback_style.content_margin_top = 15
	feedback_style.content_margin_bottom = 15
	
	var feedback_panel = $MainScroll/TavernContainer/MainVBox/FeedbackSection
	feedback_panel.add_theme_stylebox_override("panel", feedback_style)
	
	# Set text colors
	setup_text_colors()
	
	# Style buttons
	setup_button_styles()

func setup_text_colors():
	# Title styling
	var title = $MainScroll/TavernContainer/MainVBox/HeaderSection/TitleLabel
	title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
	
	# Subtitle styling  
	var subtitle = $MainScroll/TavernContainer/MainVBox/HeaderSection/SubtitleLabel
	subtitle.add_theme_color_override("font_color", Color("#CD853F"))  # Peru
	
	# Version styling
	var version = $MainScroll/TavernContainer/MainVBox/HeaderSection/VersionLabel
	version.add_theme_color_override("font_color", Color("#8B4513"))  # Saddle brown
	
	# Stats labels
	var level_label = $MainScroll/TavernContainer/MainVBox/CharacterStatsPanel/StatsVBox/LevelHBox/LevelLabel
	level_label.add_theme_color_override("font_color", Color("#DAA520"))
	
	var xp_label = $MainScroll/TavernContainer/MainVBox/CharacterStatsPanel/StatsVBox/XPHBox/XPLabel
	xp_label.add_theme_color_override("font_color", Color("#DAA520"))
	
	# Dorin's name
	var dorin_name = $MainScroll/TavernContainer/MainVBox/DorinSection/DorinVBox/DorinNameLabel
	dorin_name.add_theme_color_override("font_color", Color("#DAA520"))
	
	# Dorin's message
	var dorin_message = $MainScroll/TavernContainer/MainVBox/DorinSection/DorinVBox/DorinMessageLabel
	dorin_message.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat
	
	# Quest board title
	var quest_title = $MainScroll/TavernContainer/MainVBox/QuestBoardSection/QuestBoardTitle
	quest_title.add_theme_color_override("font_color", Color("#DAA520"))
	
	# Maslow title
	var maslow_title = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/MaslowTitle
	maslow_title.add_theme_color_override("font_color", Color("#DAA520"))
	
	# Tier labels
	setup_tier_colors()

func setup_tier_colors():
	# Physiological (unlocked)
	var physio_label = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/PhysiologicalTier/PhysioLabel
	physio_label.add_theme_color_override("font_color", Color("#32CD32"))  # Lime green (unlocked)
	
	var physio_status = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/PhysiologicalTier/PhysioStatus
	physio_status.add_theme_color_override("font_color", Color("#32CD32"))
	
	# Safety (locked)
	var safety_label = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/SafetyTier/SafetyLabel
	safety_label.add_theme_color_override("font_color", Color("#CD853F"))  # Peru (locked)
	
	var safety_status = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/SafetyTier/SafetyStatus
	safety_status.add_theme_color_override("font_color", Color("#8B4513"))  # Saddle brown
	
	# Continue for other tiers...
	var love_label = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/LoveTier/LoveLabel
	love_label.add_theme_color_override("font_color", Color("#CD853F"))
	
	var love_status = $MainScroll/TavernContainer/MainVBox/MaslowSection/MaslowVBox/LoveTier/LoveStatus
	love_status.add_theme_color_override("font_color", Color("#8B4513"))

func setup_button_styles():
	# Generate Quest button
	var quest_button = $MainScroll/TavernContainer/MainVBox/QuestBoardSection/GenerateQuestButton
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("#DAA520")  # Goldenrod
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color("#FFD700")  # Gold
	button_hover.corner_radius_bottom_left = 8
	button_hover.corner_radius_bottom_right = 8
	button_hover.corner_radius_top_left = 8
	button_hover.corner_radius_top_right = 8
	
	quest_button.add_theme_stylebox_override("normal", button_style)
	quest_button.add_theme_stylebox_override("hover", button_hover)
	quest_button.add_theme_color_override("font_color", Color("#2F4F4F"))  # Dark text
	
	# Style navigation buttons
	style_navigation_buttons()

func style_navigation_buttons():
	"""Apply styling to navigation buttons"""
	# Tavern button (current page - different style)
	if top_tavern_button:
		var current_style = StyleBoxFlat.new()
		current_style.bg_color = Color("#8B4513")  # Saddle brown (active)
		current_style.corner_radius_bottom_left = 8
		current_style.corner_radius_bottom_right = 8
		current_style.corner_radius_top_left = 8
		current_style.corner_radius_top_right = 8
		current_style.border_width_bottom = 2
		current_style.border_width_top = 2
		current_style.border_width_left = 2
		current_style.border_width_right = 2
		current_style.border_color = Color("#DAA520")  # Gold border
		
		top_tavern_button.add_theme_stylebox_override("normal", current_style)
		top_tavern_button.add_theme_color_override("font_color", Color("#DAA520"))  # Gold text
	
	# Profile button (inactive page)
	if top_profile_button:
		var inactive_style = StyleBoxFlat.new()
		inactive_style.bg_color = Color("#5D4037")  # Brown
		inactive_style.corner_radius_bottom_left = 8
		inactive_style.corner_radius_bottom_right = 8
		inactive_style.corner_radius_top_left = 8
		inactive_style.corner_radius_top_right = 8
		
		var inactive_hover = StyleBoxFlat.new()
		inactive_hover.bg_color = Color("#8B4513")  # Darker brown on hover
		inactive_hover.corner_radius_bottom_left = 8
		inactive_hover.corner_radius_bottom_right = 8
		inactive_hover.corner_radius_top_left = 8
		inactive_hover.corner_radius_top_right = 8
		
		top_profile_button.add_theme_stylebox_override("normal", inactive_style)
		top_profile_button.add_theme_stylebox_override("hover", inactive_hover)
		top_profile_button.add_theme_color_override("font_color", Color("#F5DEB3"))  # Wheat text
	
	# Style top navigation buttons (primary navigation)
	style_top_navigation_buttons()

func style_top_navigation_buttons():
	"""Apply prominent styling to top navigation buttons"""
	# Top Tavern button (current page - very visible)
	if top_tavern_button:
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color("#DAA520")  # Goldenrod (very active)
		active_style.corner_radius_bottom_left = 12
		active_style.corner_radius_bottom_right = 12
		active_style.corner_radius_top_left = 12
		active_style.corner_radius_top_right = 12
		active_style.border_width_bottom = 3
		active_style.border_width_top = 3
		active_style.border_width_left = 3
		active_style.border_width_right = 3
		active_style.border_color = Color("#FFD700")  # Bright gold border
		
		top_tavern_button.add_theme_stylebox_override("normal", active_style)
		top_tavern_button.add_theme_color_override("font_color", Color("#2F4F4F"))  # Dark text
		top_tavern_button.add_theme_font_size_override("font_size", 18)
	
	# Top Profile button (inactive but very clickable)
	if top_profile_button:
		var clickable_style = StyleBoxFlat.new()
		clickable_style.bg_color = Color("#8B4513")  # Saddle brown
		clickable_style.corner_radius_bottom_left = 12
		clickable_style.corner_radius_bottom_right = 12
		clickable_style.corner_radius_top_left = 12
		clickable_style.corner_radius_top_right = 12
		
		var clickable_hover = StyleBoxFlat.new()
		clickable_hover.bg_color = Color("#DAA520")  # Gold on hover
		clickable_hover.corner_radius_bottom_left = 12
		clickable_hover.corner_radius_bottom_right = 12
		clickable_hover.corner_radius_top_left = 12
		clickable_hover.corner_radius_top_right = 12
		
		top_profile_button.add_theme_stylebox_override("normal", clickable_style)
		top_profile_button.add_theme_stylebox_override("hover", clickable_hover)
		top_profile_button.add_theme_color_override("font_color", Color("#F5DEB3"))  # Wheat text
		top_profile_button.add_theme_font_size_override("font_size", 18)

# Navigation Event Handlers
func _on_profile_button_pressed():
	"""Handle Profile button press - switch to Profile scene"""
	print("ð¤ Switching to Profile scene...")
	get_tree().change_scene_to_file("res://scenes/ProfileScene.tscn")

func _on_tavern_button_pressed():
	"""Handle Tavern button press - already in Tavern, just log"""
	print("ð° Already in Tavern!")

# Enhanced connect function to include navigation
func connect_navigation_buttons():
	"""Connect navigation buttons"""
	# Connect top navigation buttons (primary navigation)
	if top_profile_button:
		top_profile_button.pressed.connect(_on_profile_button_pressed)
		print("â Top Profile button connected")
	else:
		print("â Top Profile button not found!")
	
	if top_tavern_button:
		top_tavern_button.pressed.connect(_on_tavern_button_pressed)
		print("â Top Tavern button connected")
	else:
		print("â Top Tavern button not found!")
