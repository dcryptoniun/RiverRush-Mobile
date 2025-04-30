extends CanvasLayer

@onready var admob: Admob = $Admob as Admob

var _is_interstitial_loaded: bool = false
# This script handles the pause menu functionality

func _ready():
	# Make sure the pause menu is hidden when the game starts
	visible = false
	admob.initialize()

# Resume button handler
func _on_resume_button_pressed():
	# Hide the pause menu
	visible = false
	# Resume the game
	get_tree().paused = false

# Restart button handler
func _on_restart_button_pressed():
	# Resume the game before restarting
	get_tree().paused = false
	# Reload the current scene
	get_tree().reload_current_scene()

# Main menu button handler
func _on_main_menu_button_pressed():
	if _is_interstitial_loaded:
		_is_interstitial_loaded = false
		admob.show_interstitial_ad()
	else:
		admob.load_interstitial_ad()
	# Resume the game before changing scenes
	get_tree().paused = false
	
	# Load the main menu scene
	var main_menu_scene = load("res://scenes/main_menu.tscn").instantiate()
	
	# Get the current scene to remove it later
	var current_scene = get_tree().current_scene
	
	# Add the new scene to the tree
	get_tree().root.add_child(main_menu_scene)
	
	# Set the new scene as current
	get_tree().current_scene = main_menu_scene
	
	# Remove the old scene
	get_tree().root.remove_child(current_scene)
	current_scene.queue_free()


func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	admob.load_interstitial_ad()


func _on_admob_interstitial_ad_loaded(ad_id: String) -> void:
	_is_interstitial_loaded = true
