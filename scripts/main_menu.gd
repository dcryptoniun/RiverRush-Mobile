extends Control

# Reference to the player count option button
@onready var player_count_option = $CanvasLayer/MarginContainer/VBoxContainer/OptionButton

func _ready() -> void:
	# Set default selection to 2 players (index 0)
	player_count_option.select(0)


func _on_start_button_pressed() -> void:
	await RenderingServer.frame_post_draw
	
	# Get the selected player count (2, 3, or 4)
	var selected_index = player_count_option.selected
	var player_count = selected_index + 2  # Convert index to actual player count
	
	# Create the game scene and set the player count parameter
	var game_scene = load("res://scenes/game_board.tscn").instantiate()
	game_scene.set_meta("player_count", player_count)
	
	# Get the current scene to remove it later
	var current_scene = get_tree().current_scene
	
	# Add the new scene to the tree
	get_tree().root.add_child(game_scene)
	
	# Set the new scene as current
	get_tree().current_scene = game_scene
	
	# Remove the old scene
	get_tree().root.remove_child(current_scene)
	current_scene.queue_free()
