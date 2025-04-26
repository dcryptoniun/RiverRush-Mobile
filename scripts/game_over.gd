extends CanvasLayer

# This script handles the game over menu functionality

# Signal to notify when a player has reached the end
signal player_reached_end(player_index)

# Array to store player rankings
var player_rankings = []

func _ready():
	# Make sure the game over menu is hidden when the game starts
	visible = false
	
	# Hide rank labels based on player count
	var player_count = 2  # Default
	
	# Try to get player count from game board
	var game_board = get_tree().get_current_scene()
	if game_board and game_board.has_method("get_player_count"):
		player_count = game_board.get_player_count()
	elif game_board and game_board.has_meta("player_count"):
		player_count = game_board.get_meta("player_count")
	
	# Hide unused rank labels
	for i in range(4):
		var rank_label = get_node("VBoxContainer/RankingsContainer/Rank" + str(i + 1))
		if rank_label:
			rank_label.visible = i < player_count

# Function to show the game over screen with rankings
func show_game_over(rankings):
	# Store the rankings
	player_rankings = rankings
	
	# Update the ranking labels
	for i in range(rankings.size()):
		var rank_label = get_node_or_null("VBoxContainer/RankingsContainer/Rank" + str(i + 1))
		if rank_label:
			var suffix = "th"
			if i == 0:
				suffix = "st"
			elif i == 1:
				suffix = "nd"
			elif i == 2:
				suffix = "rd"
			
			rank_label.text = str(i + 1) + suffix + ": Player " + str(rankings[i] + 1)
			rank_label.visible = true
	
	# Show the game over menu
	visible = true
	
	# Pause the game
	get_tree().paused = true

# Restart button handler
func _on_restart_button_pressed():
	# Resume the game before restarting
	get_tree().paused = false
	# Reload the current scene
	get_tree().reload_current_scene()

# Main menu button handler
func _on_main_menu_button_pressed():
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