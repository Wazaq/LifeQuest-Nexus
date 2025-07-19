extends Control

# Panels
@onready var game_explanation_panel: PanelContainer = $MainScroll/WelcomeContainer/MainVBox/GameExplanationPanel
@onready var game_guide_panel: PanelContainer = $MainScroll/WelcomeContainer/MainVBox/GameGuidePanel
@onready var features_panel: PanelContainer = $MainScroll/WelcomeContainer/MainVBox/FeaturesPanel
@onready var features_text: Label = $MainScroll/WelcomeContainer/MainVBox/FeaturesPanel/FeaturesText
#Buttons
@onready var prev_button: Button = $MainScroll/WelcomeContainer/MainVBox/ButtonsContainer/PrevButton
@onready var next_button: Button = $MainScroll/WelcomeContainer/MainVBox/ButtonsContainer/NextButton

# OAuth UI elements (to be added to scene)
var google_login_button: Button
var skip_login_button: Button
var login_status_label: Label

# Panel array so I can control the prev/next easier (I hope)
var panelArray = []
var current_step = 0
var max_step = 2
var show_login_option = true  # Show OAuth login option
var pending_oauth_url = ""

func _ready() -> void:
	
	panelArray = [game_explanation_panel,game_guide_panel,features_panel]
	
	setup_welcome_styling()
	connect_buttons()
	setup_oauth_ui()
	connect_oauth_signals()
	_inital_panel_loader()
	
	#Features text is now handled in the scene file
	
func _inital_panel_loader():
	# Load the game explanation panel first, with guide and features hidden
	show_current_panel()
	update_button_states()
	
func connect_buttons():
	"""Connect button signals"""
	if prev_button:
		prev_button.pressed.connect(_on_prev_button_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
	
		
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
	game_guide_panel.add_theme_stylebox_override("panel", panel_style)
	features_panel.add_theme_stylebox_override("panel", panel_style)
	
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
	
	var game_guide_text = $MainScroll/WelcomeContainer/MainVBox/GameGuidePanel/GameGuideText
	game_guide_text.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat
	
	var features_text_ref = $MainScroll/WelcomeContainer/MainVBox/FeaturesPanel/FeaturesText
	features_text_ref.add_theme_color_override("default_color", Color("#F5DEB3"))  # Wheat

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

# OAuth Authentication Methods
func setup_oauth_ui():
	"""Create OAuth login UI elements dynamically"""
	if not show_login_option:
		return
		
	# Create Google login button
	google_login_button = Button.new()
	google_login_button.text = "Login with Google"
	google_login_button.custom_minimum_size = Vector2(200, 40)
	
	# Create skip login button  
	skip_login_button = Button.new()
	skip_login_button.text = "Continue as Guest"
	skip_login_button.custom_minimum_size = Vector2(200, 40)
	
	# Create status label
	login_status_label = Label.new()
	login_status_label.text = "For the best experience, login to sync your progress across devices"
	login_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Add to the first panel (game explanation)
	var game_panel_vbox = game_explanation_panel.get_child(0)  # Assumes VBox structure
	if game_panel_vbox:
		# Add some spacing
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		game_panel_vbox.add_child(spacer)
		
		# Add login status label
		game_panel_vbox.add_child(login_status_label)
		
		# Add spacer
		var spacer2 = Control.new()
		spacer2.custom_minimum_size = Vector2(0, 10)
		game_panel_vbox.add_child(spacer2)
		
		# Create button container
		var button_container = HBoxContainer.new()
		button_container.alignment = BoxContainer.ALIGNMENT_CENTER
		button_container.add_child(google_login_button)
		
		var button_spacer = Control.new()
		button_spacer.custom_minimum_size = Vector2(20, 0)
		button_container.add_child(button_spacer)
		
		button_container.add_child(skip_login_button)
		game_panel_vbox.add_child(button_container)
	
	# Style the new buttons
	style_oauth_buttons()

func style_oauth_buttons():
	"""Apply styling to OAuth buttons"""
	if not google_login_button or not skip_login_button:
		return
		
	# Google button styling (blue theme)
	var google_style = StyleBoxFlat.new()
	google_style.bg_color = Color("#4285F4")  # Google blue
	google_style.corner_radius_bottom_left = 8
	google_style.corner_radius_bottom_right = 8
	google_style.corner_radius_top_left = 8
	google_style.corner_radius_top_right = 8
	
	var google_hover = StyleBoxFlat.new()
	google_hover.bg_color = Color("#357AE8")  # Darker blue
	google_hover.corner_radius_bottom_left = 8
	google_hover.corner_radius_bottom_right = 8
	google_hover.corner_radius_top_left = 8
	google_hover.corner_radius_top_right = 8
	
	google_login_button.add_theme_stylebox_override("normal", google_style)
	google_login_button.add_theme_stylebox_override("hover", google_hover)
	google_login_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Skip button styling (secondary style)
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color("#666666")  # Gray
	skip_style.corner_radius_bottom_left = 8
	skip_style.corner_radius_bottom_right = 8
	skip_style.corner_radius_top_left = 8
	skip_style.corner_radius_top_right = 8
	
	var skip_hover = StyleBoxFlat.new()
	skip_hover.bg_color = Color("#777777")  # Lighter gray
	skip_hover.corner_radius_bottom_left = 8
	skip_hover.corner_radius_bottom_right = 8
	skip_hover.corner_radius_top_left = 8
	skip_hover.corner_radius_top_right = 8
	
	skip_login_button.add_theme_stylebox_override("normal", skip_style)
	skip_login_button.add_theme_stylebox_override("hover", skip_hover)
	skip_login_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Status label styling
	login_status_label.add_theme_color_override("font_color", Color("#F5DEB3"))  # Wheat

func connect_oauth_signals():
	"""Connect OAuth-related signals"""
	# Connect button signals
	if google_login_button:
		google_login_button.pressed.connect(_on_google_login_pressed)
	if skip_login_button:
		skip_login_button.pressed.connect(_on_skip_login_pressed)
	
	# Connect APIManager OAuth signals
	if APIManager:
		APIManager.oauth_login_ready.connect(_on_oauth_login_ready)
		APIManager.oauth_login_success.connect(_on_oauth_login_success)
		APIManager.oauth_login_failed.connect(_on_oauth_login_failed)
		APIManager.authentication_state_changed.connect(_on_auth_state_changed)

# OAuth Event Handlers
func _on_google_login_pressed():
	"""Handle Google login button press"""
	print("Starting Google OAuth flow...")
	login_status_label.text = "Connecting to Google..."
	google_login_button.disabled = true
	APIManager.initiate_google_oauth()

func _on_skip_login_pressed():
	"""Handle skip login button press"""
	print("Continuing as guest...")
	hide_oauth_ui()
	# Continue with normal flow

func _on_oauth_login_ready(auth_url: String):
	"""Handle OAuth URL received from API"""
	print("OAuth URL received: ", auth_url)
	pending_oauth_url = auth_url
	login_status_label.text = "Opening Google login..."
	
	# Open URL in default browser
	OS.shell_open(auth_url)
	
	# Update UI for callback waiting
	google_login_button.text = "Waiting for login..."
	login_status_label.text = "Complete login in your browser, then return here"

func _on_oauth_login_success(user_data: Dictionary):
	"""Handle successful OAuth login"""
	print("OAuth login successful! Welcome ", user_data.get("name", "User"))
	login_status_label.text = "Login successful! Welcome " + user_data.get("name", "User")
	google_login_button.text = "Logged in as " + user_data.get("name", "User")
	google_login_button.disabled = true
	skip_login_button.visible = false
	
	# Auto-proceed after short delay
	await get_tree().create_timer(2.0).timeout
	hide_oauth_ui()

func _on_oauth_login_failed(error_message: String):
	"""Handle OAuth login failure"""
	print("OAuth login failed: ", error_message)
	login_status_label.text = "Login failed: " + error_message
	google_login_button.text = "Retry Google Login"
	google_login_button.disabled = false

func _on_auth_state_changed(authenticated: bool):
	"""Handle authentication state changes"""
	if authenticated:
		print("User is now authenticated")
	else:
		print("User is not authenticated")

func hide_oauth_ui():
	"""Hide OAuth login elements"""
	if google_login_button:
		google_login_button.visible = false
	if skip_login_button:
		skip_login_button.visible = false
	if login_status_label:
		login_status_label.visible = false
