class_name SettingsScene
extends Control

# UI References
@onready var feedback_form_button: Button = $MainScroll/SettingsContainer/MainVBox/HelpSection/HelpVBox/ButtonsHBox/FeedbackFormButton
@onready var discord_button: Button = $MainScroll/SettingsContainer/MainVBox/HelpSection/HelpVBox/ButtonsHBox/DiscordButton
@onready var refresh_button: Button = $MainScroll/SettingsContainer/MainVBox/AlphaControlsSection/AlphaVBox/AlphaButtonsVBox/RefreshButton
@onready var reset_button: Button = $MainScroll/SettingsContainer/MainVBox/AlphaControlsSection/AlphaVBox/AlphaButtonsVBox/ResetButton
@onready var nuclear_button: Button = $MainScroll/SettingsContainer/MainVBox/AlphaControlsSection/AlphaVBox/AlphaButtonsVBox/NuclearButton

func _ready():
	setup_settings_styling()
	connect_settings_buttons()

func connect_settings_buttons():
	"""Connect all settings buttons to their handlers"""
	
	# Help section buttons
	if feedback_form_button:
		feedback_form_button.pressed.connect(_on_feedback_button_pressed)
	
	if discord_button:
		discord_button.pressed.connect(_on_discord_button_pressed)
	
	# Alpha control buttons
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_button_pressed)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	if nuclear_button:
		nuclear_button.pressed.connect(_on_nuclear_button_pressed)
	
	print("Settings buttons connected")

func _on_feedback_button_pressed():
	"""Handle feedback form button press"""
	print("📝 Opening feedback form...")
	OS.shell_open("https://forms.gle/tpgCUKuEh9aTbk9x9")

func _on_discord_button_pressed():
	"""Handle Discord button press"""
	print("💬 Opening Discord...")
	OS.shell_open("https://discord.gg/zxy7EduTYA")

func _on_refresh_button_pressed():
	"""Handle refresh user data button press"""
	print("🔄 Refreshing user data...")
	# TODO: Implement user data refresh functionality
	show_temporary_message("User data refresh functionality coming soon!")

func _on_reset_button_pressed():
	"""Handle reset progress button press"""
	print("⚠️ Reset progress requested...")
	# TODO: Implement progress reset with confirmation
	show_temporary_message("Progress reset functionality coming soon!")

func _on_nuclear_button_pressed():
	"""Handle nuclear launch button press"""
	print("☢️ Nuclear launch requested...")
	# TODO: Implement full reset with strong confirmation
	show_temporary_message("Nuclear launch functionality coming soon!")

func show_temporary_message(message: String):
	"""Show a temporary message to the user"""
	print("💬 Message: ", message)
	# TODO: Implement proper toast notification system

func setup_settings_styling():
	"""Apply consistent styling to settings elements"""
	
	# Style main container
	var settings_container = $MainScroll/SettingsContainer
	if settings_container:
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
		main_style.content_margin_left = 20
		main_style.content_margin_right = 20
		main_style.content_margin_top = 20
		main_style.content_margin_bottom = 20
		
		settings_container.add_theme_stylebox_override("panel", main_style)
	
	# Style text elements
	setup_text_styling()
	
	# Style sections
	setup_section_styling()
	
	# Style buttons
	setup_button_styling()

func setup_text_styling():
	"""Apply text styling consistent with tavern theme"""
	
	# Title styling
	var title = $MainScroll/SettingsContainer/MainVBox/HeaderSection/TitleLabel
	if title:
		title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
		title.add_theme_font_size_override("font_size", 24)
	
	# Subtitle styling  
	var subtitle = $MainScroll/SettingsContainer/MainVBox/HeaderSection/SubtitleLabel
	if subtitle:
		subtitle.add_theme_color_override("font_color", Color("#CD853F"))  # Peru
		subtitle.add_theme_font_size_override("font_size", 16)
	
	# Section titles
	var help_title = $MainScroll/SettingsContainer/MainVBox/HelpSection/HelpVBox/HelpTitle
	if help_title:
		help_title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
		help_title.add_theme_font_size_override("font_size", 18)
	
	var alpha_title = $MainScroll/SettingsContainer/MainVBox/AlphaControlsSection/AlphaVBox/AlphaTitle
	if alpha_title:
		alpha_title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
		alpha_title.add_theme_font_size_override("font_size", 18)
	
	# Description text
	var help_desc = $MainScroll/SettingsContainer/MainVBox/HelpSection/HelpVBox/HelpDescription
	if help_desc:
		help_desc.add_theme_color_override("font_color", Color("#F5DEB3"))  # Wheat
	
	var alpha_desc = $MainScroll/SettingsContainer/MainVBox/AlphaControlsSection/AlphaVBox/AlphaDescription
	if alpha_desc:
		alpha_desc.add_theme_color_override("font_color", Color("#F5DEB3"))  # Wheat

func setup_section_styling():
	"""Style the section panels"""
	
	# Help section styling
	var help_section = $MainScroll/SettingsContainer/MainVBox/HelpSection
	if help_section:
		var help_style = StyleBoxFlat.new()
		help_style.bg_color = Color("#5D4037", 0.3)  # Semi-transparent brown
		help_style.corner_radius_bottom_left = 10
		help_style.corner_radius_bottom_right = 10
		help_style.corner_radius_top_left = 10
		help_style.corner_radius_top_right = 10
		help_style.border_width_bottom = 1
		help_style.border_width_top = 1
		help_style.border_width_left = 1
		help_style.border_width_right = 1
		help_style.border_color = Color("#8B4513")
		help_style.content_margin_left = 15
		help_style.content_margin_right = 15
		help_style.content_margin_top = 15
		help_style.content_margin_bottom = 15
		
		help_section.add_theme_stylebox_override("panel", help_style)
	
	# Alpha controls section styling
	var alpha_section = $MainScroll/SettingsContainer/MainVBox/AlphaControlsSection
	if alpha_section:
		var alpha_style = StyleBoxFlat.new()
		alpha_style.bg_color = Color("#3D2914")  # Dark brown
		alpha_style.corner_radius_bottom_left = 10
		alpha_style.corner_radius_bottom_right = 10
		alpha_style.corner_radius_top_left = 10
		alpha_style.corner_radius_top_right = 10
		alpha_style.border_width_bottom = 1
		alpha_style.border_width_top = 1
		alpha_style.border_width_left = 1
		alpha_style.border_width_right = 1
		alpha_style.border_color = Color("#8B4513")  # Saddle brown border
		alpha_style.content_margin_left = 15
		alpha_style.content_margin_right = 15
		alpha_style.content_margin_top = 15
		alpha_style.content_margin_bottom = 15
		
		alpha_section.add_theme_stylebox_override("panel", alpha_style)

func setup_button_styling():
	"""Apply consistent button styling"""
	
	# Help section buttons (reuse tavern styling)
	style_help_buttons()
	
	# Alpha control buttons (warning styling)
	style_alpha_buttons()

func style_help_buttons():
	"""Style help section buttons like tavern"""
	
	# Feedback Form button
	if feedback_form_button:
		var feedback_style = StyleBoxFlat.new()
		feedback_style.bg_color = Color("#5D4037")  # Brown
		feedback_style.corner_radius_bottom_left = 8
		feedback_style.corner_radius_bottom_right = 8
		feedback_style.corner_radius_top_left = 8
		feedback_style.corner_radius_top_right = 8
		feedback_style.content_margin_top = 8
		feedback_style.content_margin_bottom = 8
		feedback_style.content_margin_left = 15
		feedback_style.content_margin_right = 15
		
		var feedback_hover = StyleBoxFlat.new()
		feedback_hover.bg_color = Color("#8B4513")  # Lighter brown on hover
		feedback_hover.corner_radius_bottom_left = 8
		feedback_hover.corner_radius_bottom_right = 8
		feedback_hover.corner_radius_top_left = 8
		feedback_hover.corner_radius_top_right = 8
		feedback_hover.content_margin_top = 8
		feedback_hover.content_margin_bottom = 8
		feedback_hover.content_margin_left = 15
		feedback_hover.content_margin_right = 15
		
		feedback_form_button.add_theme_stylebox_override("normal", feedback_style)
		feedback_form_button.add_theme_stylebox_override("hover", feedback_hover)
		feedback_form_button.add_theme_color_override("font_color", Color("#FFFFFF"))  # White text
	
	# Discord button
	if discord_button:
		var discord_style = StyleBoxFlat.new()
		discord_style.bg_color = Color("#7289DA")  # Discord brand blue
		discord_style.corner_radius_bottom_left = 8
		discord_style.corner_radius_bottom_right = 8
		discord_style.corner_radius_top_left = 8
		discord_style.corner_radius_top_right = 8
		discord_style.content_margin_top = 8
		discord_style.content_margin_bottom = 8
		discord_style.content_margin_left = 15
		discord_style.content_margin_right = 15
		
		var discord_hover = StyleBoxFlat.new()
		discord_hover.bg_color = Color("#5865F2")  # Discord brand purple on hover
		discord_hover.corner_radius_bottom_left = 8
		discord_hover.corner_radius_bottom_right = 8
		discord_hover.corner_radius_top_left = 8
		discord_hover.corner_radius_top_right = 8
		discord_hover.content_margin_top = 8
		discord_hover.content_margin_bottom = 8
		discord_hover.content_margin_left = 15
		discord_hover.content_margin_right = 15
		
		discord_button.add_theme_stylebox_override("normal", discord_style)
		discord_button.add_theme_stylebox_override("hover", discord_hover)
		discord_button.add_theme_color_override("font_color", Color("#FFFFFF"))  # White text

func style_alpha_buttons():
	"""Style alpha control buttons with warning colors"""
	
	var alpha_buttons = [refresh_button, reset_button, nuclear_button]
	var button_colors = [
		{"normal": Color("#4169E1"), "hover": Color("#6495ED")},  # Royal blue for refresh
		{"normal": Color("#FF8C00"), "hover": Color("#FFA500")},  # Dark orange for reset
		{"normal": Color("#DC143C"), "hover": Color("#FF1493")}   # Crimson for nuclear
	]
	
	for i in range(alpha_buttons.size()):
		var button = alpha_buttons[i]
		if button:
			var colors = button_colors[i]
			
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = colors.normal
			normal_style.corner_radius_bottom_left = 8
			normal_style.corner_radius_bottom_right = 8
			normal_style.corner_radius_top_left = 8
			normal_style.corner_radius_top_right = 8
			normal_style.content_margin_top = 10
			normal_style.content_margin_bottom = 10
			normal_style.content_margin_left = 15
			normal_style.content_margin_right = 15
			
			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = colors.hover
			hover_style.corner_radius_bottom_left = 8
			hover_style.corner_radius_bottom_right = 8
			hover_style.corner_radius_top_left = 8
			hover_style.corner_radius_top_right = 8
			hover_style.content_margin_top = 10
			hover_style.content_margin_bottom = 10
			hover_style.content_margin_left = 15
			hover_style.content_margin_right = 15
			
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_color_override("font_color", Color("#FFFFFF"))  # White text
			button.add_theme_font_size_override("font_size", 14)
