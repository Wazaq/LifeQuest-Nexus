extends Control

# UI elements references
@onready var title: Label = $MainScroll/WelcomeContainer/MainVBox/Title
@onready var login_text: Label = $MainScroll/WelcomeContainer/MainVBox/LoginSection/LoginText
@onready var login_section: VBoxContainer = $MainScroll/WelcomeContainer/MainVBox/LoginSection

# OAuth UI elements (to be added dynamically)
var google_login_button: Button
var skip_login_button: Button
var login_status_label: Label

var show_login_option = true  # Show OAuth login option
var pending_oauth_url = ""

func _ready() -> void:
	setup_welcome_styling()
	
	# Check authentication state and route accordingly
	check_authentication_and_route()

func check_authentication_and_route():
	"""Check user authentication state and route appropriately"""
	
	# Check if user is already authenticated
	if APIManager and APIManager.is_authenticated and APIManager.current_user_id != "":
		print("User already authenticated - routing directly to Tavern")
		print("User ID: ", APIManager.current_user_id)
		
		# Use call_deferred to avoid scene tree conflicts
		call_deferred("_route_to_tavern")
		return
	
	# User is not authenticated - show landing page with OAuth options
	print("New or unauthenticated user - showing landing page")
	setup_oauth_ui()

func _route_to_tavern():
	"""Deferred function to safely change to Tavern scene"""
	get_tree().change_scene_to_file("res://scenes/TavernMain.tscn")

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
	
	# Set up text colors
	setup_welcome_text_colors()

func setup_welcome_text_colors():
	"""Apply consistent text colors with outline for visibility over background"""
	# Title styling - larger font with outline for visibility
	title.add_theme_color_override("font_color", Color("#FFD700"))  # Bright gold
	title.add_theme_color_override("font_shadow_color", Color("#000000"))  # Black shadow
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	
	# Login text styling
	login_text.add_theme_color_override("font_color", Color("#F5DEB3"))  # Wheat
	login_text.add_theme_color_override("font_shadow_color", Color("#000000"))  # Black shadow
	login_text.add_theme_constant_override("shadow_offset_x", 1)
	login_text.add_theme_constant_override("shadow_offset_y", 1)

# OAuth Authentication Methods
func setup_oauth_ui():
	"""Create OAuth login UI elements dynamically - only for unauthenticated users"""
	
	# Only show OAuth UI if user is not authenticated
	if APIManager and APIManager.is_authenticated:
		print("User already authenticated - skipping OAuth UI")
		show_login_option = false
		return
	
	if not show_login_option:
		return
		
	# Create Google login button
	google_login_button = Button.new()
	google_login_button.text = "Sign up with Google"
	google_login_button.custom_minimum_size = Vector2(250, 50)
	
	# Create skip login button  
	skip_login_button = Button.new()
	skip_login_button.text = "Continue as Guest"
	skip_login_button.custom_minimum_size = Vector2(250, 50)
	
	# Create status label
	login_status_label = Label.new()
	login_status_label.text = "For the best experience, sign up to sync your progress across devices"
	login_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Add to the login section
	if login_section:
		# Add login status label
		login_section.add_child(login_status_label)
		
		# Add spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 15)
		login_section.add_child(spacer)
		
		# Add Google button
		login_section.add_child(google_login_button)
		
		# Add spacer between buttons
		var button_spacer = Control.new()
		button_spacer.custom_minimum_size = Vector2(0, 10)
		login_section.add_child(button_spacer)
		
		# Add guest button
		login_section.add_child(skip_login_button)
	
	# Style the new buttons
	style_oauth_buttons()
	
	# Now connect the signals since buttons exist
	connect_oauth_signals()

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
	print("Connecting OAuth signals...")
	
	# Connect button signals with null checks
	if google_login_button:
		google_login_button.pressed.connect(_on_google_login_pressed)
		print("Google login button signal connected")
	else:
		print("WARNING: google_login_button is null, cannot connect signal")
		
	if skip_login_button:
		skip_login_button.pressed.connect(_on_skip_login_pressed)
		print("Skip login button signal connected")
	else:
		print("WARNING: skip_login_button is null, cannot connect signal")
	
	# Connect APIManager OAuth signals
	if APIManager:
		APIManager.oauth_login_ready.connect(_on_oauth_login_ready)
		APIManager.oauth_login_success.connect(_on_oauth_login_success)
		APIManager.oauth_login_failed.connect(_on_oauth_login_failed)
		APIManager.authentication_state_changed.connect(_on_auth_state_changed)
		print("APIManager OAuth signals connected")
	else:
		print("WARNING: APIManager is null, cannot connect OAuth signals")

# OAuth Event Handlers
func _on_google_login_pressed():
	"""Handle Google login button press"""
	print("Google login button pressed - OAuth flow starting...")
	login_status_label.text = "Connecting to Google..."
	google_login_button.disabled = true
	APIManager.initiate_google_oauth()

func _on_skip_login_pressed():
	"""Handle skip login button press"""
	print("Skip login button pressed - creating guest account...")
	APIManager.create_guest_user();
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
