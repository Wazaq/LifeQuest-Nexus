extends Control

# Panels
@onready var game_explanation_panel: PanelContainer = $MainScroll/WelcomeContainer/MainVBox/GameExplanationPanel
@onready var alpha_explanation_panel: PanelContainer = $MainScroll/WelcomeContainer/MainVBox/AlphaExplanationPanel
@onready var patch_notes_panel: PanelContainer = $MainScroll/WelcomeContainer/MainVBox/PatchNotesPanel
@onready var patch_notes_text: Label = $MainScroll/WelcomeContainer/MainVBox/PatchNotesPanel/PatchText
#Buttons
@onready var prev_button: Button = $MainScroll/WelcomeContainer/MainVBox/ButtonsContainer/PrevButton
@onready var next_button: Button = $MainScroll/WelcomeContainer/MainVBox/ButtonsContainer/NextButton

# Panel array so I can control the prev/next easier (I hope)
var panelArray = []
var current_step = 0
var max_step = 2

func _ready() -> void:
	
	panelArray = [game_explanation_panel,alpha_explanation_panel,patch_notes_panel]
	
	setup_welcome_styling()
	connect_buttons()
	_inital_panel_loader()
	
	#Patch Notes handled here for now
	patch_notes_text.text = """
Alpha v0.1.0 (7/6/25):
- Auto player profile creation
- Basic quest system  
- XP tracking and persistence
- User account management
"""
	
func _inital_panel_loader():
	# For now we want to have the Game panel loaded, and the Aplha and patch panel hidden
	show_current_panel()
	update_button_states()
	
func connect_buttons():
	"""Connect button signals"""
	print("WELCOME: Connecting the buttons")
	if prev_button:
		prev_button.pressed.connect(_on_prev_button_pressed)
		print("WECLCOME: Previous button pressed!")
	else:
		print("Prev button not found!")
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
		print("WELCOME: Next button pressed!")
	else:
		print("Next button not found!")
		
	print("WELCOME: END Connecting the buttons")
	
		
func _on_prev_button_pressed():
	# Move to the previous panel
	if current_step > 0:
		current_step -= 1
		show_current_panel()
		update_button_states()
	
func _on_next_button_pressed():
	# Move to the next panel or go to tavern if on last panel
	if current_step < max_step:
		current_step += 1
		show_current_panel()
		update_button_states()
	else:
		# On last panel - go to tavern
		get_tree().change_scene_to_file("res://scenes/TavernMain.tscn")
	
func show_current_panel():
	for i in range(panelArray.size()):
		panelArray[i].visible = (i == current_step)

func update_button_states():
	# Hide prev button on first panel
	prev_button.visible = (current_step > 0)
	
	# Change next button text on last panel
	if current_step == max_step:
		next_button.text = "Enter the Tavern!"
	else:
		next_button.text = "Next -->"

func setup_welcome_styling():
	"""Apply consistent styling to match the tavern theme"""
	
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
	main_style.content_margin_left = 20
	main_style.content_margin_right = 20
	main_style.content_margin_top = 20
	main_style.content_margin_bottom = 20
	
	# Apply to main welcome container
	var welcome_container = $MainScroll/WelcomeContainer
	welcome_container.add_theme_stylebox_override("panel", main_style)
	
	# Style the content panels with dark brown theme
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#3D2914")  # Dark brown
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
	
	# Apply panel styling to all content panels
	game_explanation_panel.add_theme_stylebox_override("panel", panel_style)
	alpha_explanation_panel.add_theme_stylebox_override("panel", panel_style)
	patch_notes_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Set up text colors
	setup_welcome_text_colors()
	
	# Style buttons
	setup_welcome_button_styles()

func setup_welcome_text_colors():
	"""Apply consistent text colors"""
	# Title styling
	var title = $MainScroll/WelcomeContainer/MainVBox/HeaderSection/Title
	title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
	
	# Subtitle styling  
	var subtitle = $MainScroll/WelcomeContainer/MainVBox/HeaderSection/Subtitle
	subtitle.add_theme_color_override("font_color", Color("#CD853F"))  # Peru
	
	# Content text styling
	var game_text = $MainScroll/WelcomeContainer/MainVBox/GameExplanationPanel/GameText
	game_text.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat
	
	var alpha_text = $MainScroll/WelcomeContainer/MainVBox/AlphaExplanationPanel/AlphaText
	alpha_text.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat
	
	var patch_text = $MainScroll/WelcomeContainer/MainVBox/PatchNotesPanel/PatchText
	patch_text.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat

func setup_welcome_button_styles():
	"""Apply consistent button styling"""
	
	# Create button styles
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
	
	# Apply to navigation buttons
	prev_button.add_theme_stylebox_override("normal", button_style)
	prev_button.add_theme_stylebox_override("hover", button_hover)
	prev_button.add_theme_color_override("font_color", Color("#2F4F4F"))  # Dark text
	
	next_button.add_theme_stylebox_override("normal", button_style)
	next_button.add_theme_stylebox_override("hover", button_hover)
	next_button.add_theme_color_override("font_color", Color("#2F4F4F"))  # Dark text
