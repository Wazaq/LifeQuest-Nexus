# extends Control
extends CanvasLayer
# Universal Navigation Manager - AutoLoad Singleton
# Provides slide-out navigation tray on all scenes

# Navigation tray state
var tray_is_open: bool = false
var tray_tween: Tween

# UI References (now from scene file)
@onready var hamburger_button: Button = $HamburgerButton
@onready var tray_overlay: Control = $NavigationTrayOverlay
@onready var tray_background: ColorRect = $NavigationTrayOverlay/TrayBackground
@onready var navigation_tray: PanelContainer = $NavigationTrayOverlay/NavigationTray
@onready var close_button: Button = $NavigationTrayOverlay/NavigationTray/TrayVBox/TrayHeader/CloseButton
@onready var tavern_nav_button: Button = $NavigationTrayOverlay/NavigationTray/TrayVBox/NavButtons/TavernNavButton
@onready var profile_nav_button: Button = $NavigationTrayOverlay/NavigationTray/TrayVBox/NavButtons/ProfileNavButton
@onready var settings_nav_button: Button = $NavigationTrayOverlay/NavigationTray/TrayVBox/NavButtons/SettingsNavButton

func _ready():
	# Set up the navigation overlay that persists across all scenes
	name = "NavigationManager"
	
	# CRITICAL: Ensure this appears above all other content
	# z_index = 1000
	
	# Initialize navigation tray functionality
	setup_navigation_tray()
	
	print("✅ Universal Navigation Manager loaded!")

func setup_navigation_tray():
	"""Initialize navigation tray functionality"""
	
	# Connect buttons
	hamburger_button.pressed.connect(_on_hamburger_pressed)
	close_button.pressed.connect(_on_tray_close_pressed)
	tray_background.gui_input.connect(_on_tray_background_input)
	
	# Connect navigation buttons
	tavern_nav_button.pressed.connect(_on_tavern_nav_pressed)
	profile_nav_button.pressed.connect(_on_profile_nav_pressed)
	settings_nav_button.pressed.connect(_on_settings_nav_pressed)
	
	# Apply styling
	style_navigation_elements()
	
	print("Navigation tray setup complete")

func _on_hamburger_pressed():
	"""Handle hamburger menu button press"""
	print("🍔 Hamburger button clicked!")
	toggle_navigation_tray()

func _on_tray_close_pressed():
	"""Handle tray close button press"""
	close_navigation_tray()

func _on_tray_background_input(event: InputEvent):
	"""Handle tap outside tray to close"""
	if event is InputEventMouseButton and event.pressed:
		close_navigation_tray()

func _on_tavern_nav_pressed():
	"""Handle tavern navigation button press"""
	close_navigation_tray()
	navigate_to_scene("res://scenes/TavernMain.tscn")

func _on_profile_nav_pressed():
	"""Handle profile navigation button press"""
	close_navigation_tray()
	navigate_to_scene("res://scenes/ProfileScene.tscn")

func _on_settings_nav_pressed():
	"""Handle settings navigation button press"""
	close_navigation_tray()
	navigate_to_scene("res://scenes/SettingsScene.tscn")

func navigate_to_scene(scene_path: String):
	"""Navigate to a specific scene"""
	print("🧭 Navigating to: ", scene_path)
	get_tree().change_scene_to_file(scene_path)

func toggle_navigation_tray():
	"""Toggle the navigation tray open/closed"""
	if tray_is_open:
		close_navigation_tray()
	else:
		open_navigation_tray()

func open_navigation_tray():
	"""Open the navigation tray with smooth animation"""
	if tray_is_open:
		return
	
	print("Opening universal navigation tray...")
	tray_is_open = true
	
	# Show the overlay
	tray_overlay.visible = true
	tray_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Animate tray sliding in
	if tray_tween:
		tray_tween.kill()
	
	tray_tween = create_tween()
	tray_tween.set_ease(Tween.EASE_OUT)
	tray_tween.set_trans(Tween.TRANS_CUBIC)
	tray_tween.tween_property(navigation_tray, "position:x", 0, 0.3)

func close_navigation_tray():
	"""Close the navigation tray with smooth animation"""
	if not tray_is_open:
		return
	
	print("Closing universal navigation tray...")
	tray_is_open = false
	
	# Animate tray sliding out
	if tray_tween:
		tray_tween.kill()
	
	tray_tween = create_tween()
	tray_tween.set_ease(Tween.EASE_IN)
	tray_tween.set_trans(Tween.TRANS_CUBIC)
	tray_tween.tween_property(navigation_tray, "position:x", -250, 0.3)
	
	# Hide overlay after animation
	tray_tween.tween_callback(func(): 
		tray_overlay.visible = false
		tray_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)

func style_navigation_elements():
	"""Apply styling to all navigation elements"""
	
	# Style hamburger button
	var hamburger_style = StyleBoxFlat.new()
	hamburger_style.bg_color = Color("#DAA520")  # Gold
	hamburger_style.corner_radius_bottom_left = 8
	hamburger_style.corner_radius_bottom_right = 8
	hamburger_style.corner_radius_top_left = 8
	hamburger_style.corner_radius_top_right = 8
	
	var hamburger_hover = StyleBoxFlat.new()
	hamburger_hover.bg_color = Color("#FFD700")  # Brighter gold
	hamburger_hover.corner_radius_bottom_left = 8
	hamburger_hover.corner_radius_bottom_right = 8
	hamburger_hover.corner_radius_top_left = 8
	hamburger_hover.corner_radius_top_right = 8
	
	hamburger_button.add_theme_stylebox_override("normal", hamburger_style)
	hamburger_button.add_theme_stylebox_override("hover", hamburger_hover)
	hamburger_button.add_theme_color_override("font_color", Color("#000000"))  # Black text
	hamburger_button.add_theme_font_size_override("font_size", 20)
	
	# Style navigation tray panel
	var tray_style = StyleBoxFlat.new()
	tray_style.bg_color = Color("#2F4F4F")  # Dark slate gray
	tray_style.corner_radius_bottom_right = 15
	tray_style.corner_radius_top_right = 15
	tray_style.border_width_right = 3
	tray_style.border_width_top = 3
	tray_style.border_width_bottom = 3
	tray_style.border_color = Color("#DAA520")  # Gold border
	tray_style.content_margin_left = 20
	tray_style.content_margin_right = 20
	tray_style.content_margin_top = 20
	tray_style.content_margin_bottom = 20
	
	navigation_tray.add_theme_stylebox_override("panel", tray_style)
	
	# Style navigation buttons
	style_tray_buttons()

func style_tray_buttons():
	"""Apply consistent styling to tray navigation buttons"""
	var buttons = [tavern_nav_button, profile_nav_button, settings_nav_button]
	
	for button in buttons:
		if button:
			# Normal state
			var button_style = StyleBoxFlat.new()
			button_style.bg_color = Color("#5D4037")  # Brown
			button_style.corner_radius_bottom_left = 8
			button_style.corner_radius_bottom_right = 8
			button_style.corner_radius_top_left = 8
			button_style.corner_radius_top_right = 8
			button_style.content_margin_top = 12
			button_style.content_margin_bottom = 12
			button_style.content_margin_left = 15
			button_style.content_margin_right = 15
			
			# Hover state
			var button_hover = StyleBoxFlat.new()
			button_hover.bg_color = Color("#8B4513")  # Lighter brown
			button_hover.corner_radius_bottom_left = 8
			button_hover.corner_radius_bottom_right = 8
			button_hover.corner_radius_top_left = 8
			button_hover.corner_radius_top_right = 8
			button_hover.content_margin_top = 12
			button_hover.content_margin_bottom = 12
			button_hover.content_margin_left = 15
			button_hover.content_margin_right = 15
			
			button.add_theme_stylebox_override("normal", button_style)
			button.add_theme_stylebox_override("hover", button_hover)
			button.add_theme_color_override("font_color", Color("#FFFFFF"))  # White text
			button.add_theme_font_size_override("font_size", 16)
	
	# Style current page button as active
	update_active_button()
	
	# Style other UI elements
	style_tray_ui_elements()

func update_active_button():
	"""Update which navigation button appears as active based on current scene"""
	var current_scene = get_tree().current_scene.scene_file_path
	
	# Reset all buttons to normal style first
	var buttons = [tavern_nav_button, profile_nav_button, settings_nav_button]
	for button in buttons:
		if button:
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color("#5D4037")  # Brown
			normal_style.corner_radius_bottom_left = 8
			normal_style.corner_radius_bottom_right = 8
			normal_style.corner_radius_top_left = 8
			normal_style.corner_radius_top_right = 8
			normal_style.content_margin_top = 12
			normal_style.content_margin_bottom = 12
			normal_style.content_margin_left = 15
			normal_style.content_margin_right = 15
			
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_color_override("font_color", Color("#FFFFFF"))
	
	# Style active button
	var active_button: Button = null
	if current_scene.ends_with("TavernMain.tscn"):
		active_button = tavern_nav_button
	elif current_scene.ends_with("ProfileScene.tscn"):
		active_button = profile_nav_button
	elif current_scene.ends_with("SettingsScene.tscn"):
		active_button = settings_nav_button
	
	if active_button:
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color("#DAA520")  # Gold (active)
		active_style.corner_radius_bottom_left = 8
		active_style.corner_radius_bottom_right = 8
		active_style.corner_radius_top_left = 8
		active_style.corner_radius_top_right = 8
		active_style.border_width_left = 2
		active_style.border_width_right = 2
		active_style.border_width_top = 2
		active_style.border_width_bottom = 2
		active_style.border_color = Color("#FFD700")  # Bright gold border
		active_style.content_margin_top = 12
		active_style.content_margin_bottom = 12
		active_style.content_margin_left = 15
		active_style.content_margin_right = 15
		
		active_button.add_theme_stylebox_override("normal", active_style)
		active_button.add_theme_color_override("font_color", Color("#000000"))  # Black text

func style_tray_ui_elements():
	"""Style tray header and footer elements"""
	
	# Style tray title
	var tray_title = $NavigationTrayOverlay/NavigationTray/TrayVBox/TrayHeader/TrayTitle
	if tray_title:
		tray_title.add_theme_color_override("font_color", Color("#DAA520"))  # Gold
		tray_title.add_theme_font_size_override("font_size", 18)
	
	# Style close button
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color("#8B0000")  # Dark red
	close_style.corner_radius_bottom_left = 6
	close_style.corner_radius_bottom_right = 6
	close_style.corner_radius_top_left = 6
	close_style.corner_radius_top_right = 6
	
	var close_hover = StyleBoxFlat.new()
	close_hover.bg_color = Color("#DC143C")  # Crimson
	close_hover.corner_radius_bottom_left = 6
	close_hover.corner_radius_bottom_right = 6
	close_hover.corner_radius_top_left = 6
	close_hover.corner_radius_top_right = 6
	
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", close_hover)
	close_button.add_theme_color_override("font_color", Color("#FFFFFF"))
	close_button.add_theme_font_size_override("font_size", 14)
	
	# Style footer info
	var version_info = $NavigationTrayOverlay/NavigationTray/TrayVBox/TrayFooter/VersionInfo
	var player_info = $NavigationTrayOverlay/NavigationTray/TrayVBox/TrayFooter/PlayerInfo
	
	if version_info:
		version_info.add_theme_color_override("font_color", Color("#CD853F"))  # Peru
		version_info.add_theme_font_size_override("font_size", 12)
	
	if player_info:
		player_info.add_theme_color_override("font_color", Color("#8B4513"))  # Saddle brown
		player_info.add_theme_font_size_override("font_size", 11)

# Called when scene changes to update active button
func _notification(what):
	if what == NOTIFICATION_READY:
		# Update active button when NavigationManager becomes ready after scene change
		call_deferred("update_active_button")
