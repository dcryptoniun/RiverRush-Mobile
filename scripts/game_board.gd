extends Control

# This script manages the game board functionality
# It ensures the board stays in position regardless of screen size

# Variables for dice rolling
var current_dice_value = 1
var dice_images = []
var dice_display = null
var is_rolling = false
var pending_log_movement = false  # Flag to track if log movement is pending after all dice rolls

# Variables for wood log
var wood_log_scene = preload("res://scenes/wood_log.tscn")
var wood_log = null
var log_direction = 1  # 1 for right to left, -1 for left to right
var player_move_completed = true  # Flag to track if player movement is complete

# Variables for multiple players
var player_colors = [
	Color(0.9, 0.1, 0.1, 0.8),  # Red (Player 1)
	Color(0.1, 0.1, 0.9, 0.8),  # Blue (Player 2)
	Color(0.1, 0.9, 0.1, 0.8),  # Green (Player 3)
	Color(0.9, 0.9, 0.1, 0.8)   # Yellow (Player 4)
]
var player_count = 2  # Default player count if not specified
var player_rects = []  # Array to store all player rectangles
var player_positions = []  # Array to store positions of all players
var player_checkpoints = []  # Array to store checkpoints of all players
var player_path_follows = []  # Array to store PathFollow2D nodes for each player
var player_tweens = []  # Array to store tweens for each player
var current_player_index = 0  # Index of the current player
var player_turn_label = null  # Label to display current player's turn

var stone_node_positions = {}  # Will store actual positions of stones in the scene
var path_2d = null  # Reference to Path2D for player movement
var is_moving = false  # Flag to track if player is currently moving
var pause_menu = null  # Reference to the pause menu

func _ready():
	# Initialize the game board
	print("Game board initialized")
	
	# Get player count from scene parameters if available
	if has_meta("player_count"):
		player_count = get_meta("player_count")
		print("Player count set to: ", player_count)
	elif get_tree().get_current_scene() != self and get_tree().get_current_scene().has_meta("player_count"):
		player_count = get_tree().get_current_scene().get_meta("player_count")
		print("Player count set to: ", player_count)
	
	# The board is already set up to stay centered using CanvasLayer and CenterContainer
	# This ensures it maintains its position regardless of screen resolution
	
	# Load dice images - using 1,2,3,1_b,2_b,3_b instead of 1-6
	# Load regular dice faces (1-3)
	for i in range(1, 4):
		var path = "res://assets/dice/" + str(i) + ".png"
		dice_images.append(load(path))
	
	# Load brown dice faces (1_b, 2_b, 3_b)
	for i in range(1, 4):
		var path = "res://assets/dice/" + str(i) + "_b.png"
		dice_images.append(load(path))
	
	# Get reference to dice display
	dice_display = %DiceDisplay
	
	# Set initial dice image
	if dice_display:
		dice_display.texture = dice_images[0]
		
	# Reference to the wood log scene - we don't instantiate it here anymore
	# as it's already a separate scene that will be managed independently
	
	# Get reference to Path2D for player movement
	path_2d = $Path2D
	
	# Setup pause menu
	var pause_menu_scene = load("res://scenes/pause_menu.tscn")
	if pause_menu_scene:
		pause_menu = pause_menu_scene.instantiate()
		if pause_menu:
			pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(pause_menu)
			pause_menu.visible = false
		else:
			print("Error: Failed to instantiate pause menu scene")
	else:
		print("Error: Failed to load pause menu scene")
	
	# Connect pause button signal
	
	# Store positions of all stones for player movement
	store_stone_positions()
	
	# Create player placeholders
	create_player()

# Function to handle player movement on the board (implemented below)

# Function to handle wood log movement
func move_log():
	# Only move log if player movement is complete
	if not player_move_completed:
		print("Waiting for player movement to complete before moving log...")
		return
		
	# Find the wood log in the scene tree - try different paths
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	
	# If not found, try alternative paths
	if not wood_log_node:
		# Try relative path from current node
		wood_log_node = get_node_or_null("../WoodLog")
	
	# Check if the wood log instance exists
	if not wood_log_node:
		print("Wood log not found in scene tree")
		return
	
	# Always use direction 1 for downward movement
	log_direction = 1
	
	# Call the start_movement function on the wood_log instance
	wood_log_node.start_movement(log_direction)
	
	print("Log movement triggered - moving downward from fixed position")

# Function to roll the dice
func roll_dice():
	# Check if dice is already rolling or if wood log is moving
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	if is_rolling or (wood_log_node and wood_log_node.is_moving):
		print("Cannot roll dice while log is moving or dice is already rolling")
		return
		
	is_rolling = true
	player_move_completed = false  # Reset player movement flag
	
	# Create a timer for dice animation
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.1
	timer.one_shot = false
	
	# Connect timer timeout to animation function
	timer.timeout.connect(_on_dice_animation_timeout)
	
	# Start the animation
	timer.start()
	
	# Create a timer to stop the animation
	var stop_timer = Timer.new()
	add_child(stop_timer)
	stop_timer.wait_time = 1.5
	stop_timer.one_shot = true
	stop_timer.timeout.connect(func(): 
		timer.stop()
		timer.queue_free()
		stop_timer.queue_free()
		
		# Generate final random value (1-6 representing 1,2,3,1_b,2_b,3_b)
		current_dice_value = randi() % 6 + 1
		
		# Update dice display with final value
		if dice_display:
			dice_display.texture = dice_images[current_dice_value - 1]
		
		is_rolling = false
		
		# Print the result for debugging
		print("Player ", current_player_index + 1, " rolled: ", current_dice_value)
		
		# Move player based on dice value (1-3 for regular faces)
		var steps = current_dice_value
		if steps > 3:
			steps = steps - 3  # Convert 4,5,6 to 1,2,3 for brown faces
		
		# Move current player - wood log movement will be triggered after player movement completes
		move_player(player_rects[current_player_index], steps)
		
		# Note: Wood log movement is now handled in move_player after player movement completes
	)
	stop_timer.start()

# Function for dice animation
func _on_dice_animation_timeout():
	# Show random dice face during animation
	var random_face = randi() % 6 + 1
	if dice_display:
		dice_display.texture = dice_images[random_face - 1]

# Function to handle special stone effects
func handle_stone_effect(stone_type):
	# This function will handle different effects based on stone type
	# For example: dice stone, duck stone, frog stone, rerun stone
	match stone_type:
		"dice":
			# Implement dice stone effect
			roll_dice()
		"duck":
			# Implement duck stone effect
			pass
		"frog":
			# Implement frog stone effect
			pass
		"rerun":
			# Implement rerun stone effect
			pass
		_:
			# Default stone effect
			pass

# Function to store all stone positions for player movement
func store_stone_positions():
	var stones_parent = get_node("MarginContainer/Stones")
	if not stones_parent:
		print("Error: Stones parent node not found")
		return
	
	# Loop through all stone positions in our configuration
	for pos_key in stone_positions.keys():
		var stone_data = stone_positions[pos_key]
		var stone_name = stone_data.get("name", "")
		
		# Find the corresponding node in the scene
		if stone_name != "":
			var stone_node = stones_parent.get_node_or_null(stone_name)
			if stone_node:
				# Store the global position of this stone
				stone_node_positions[pos_key] = stone_node.global_position + Vector2(stone_node.size.x/2, stone_node.size.y/2)
				print("Stored position for ", stone_name, ": ", stone_node_positions[pos_key])

# Function to create player placeholders
func create_player():
	# Get reference to the player turn label in the scene
	player_turn_label = %PlayerTurnLabel
	
	# Set initial text and color for player 1
	player_turn_label.text = "Player 1's Turn"
	player_turn_label.add_theme_color_override("font_color", player_colors[0])
	
	# Create players based on player_count
	for i in range(player_count):
		# Create a PathFollow2D for this player
		var path_follow = PathFollow2D.new()
		path_2d.add_child(path_follow)
		path_follow.loop = false  # Don't loop around the path
		path_follow.rotates = false  # Don't rotate the player along the path
		path_follow.progress_ratio = 0.0  # Start at the beginning of the path
		
		# Create a ColorRect as player placeholder
		var player = ColorRect.new()
		player.color = player_colors[i]  # Set color based on player index
		player.custom_minimum_size = Vector2(30, 30)  # Size of player
		
		# Add player to the PathFollow2D
		path_follow.add_child(player)
		
		# Center the player on the path by setting its position to be exactly centered
		# The position needs to be negative half of the player's size to center it on the path point
		player.position = Vector2(-player.custom_minimum_size.x/2, -player.custom_minimum_size.y/2)
		
		# Offset each player slightly so they're all visible
		player.position += Vector2(i * 10, i * 10)
		
		# Add player and PathFollow2D to our arrays
		player_rects.append(player)
		player_path_follows.append(path_follow)
		player_tweens.append(null)  # Initialize tween array with null values
		
		# Initialize player position and checkpoint
		player_positions.append(1)  # All players start at position 1
		player_checkpoints.append(1)  # All players start with checkpoint at position 1
	
	# Update the visual position of the current player
	update_player_visual_position()

# Function to update player visual position based on current player's position
func update_player_visual_position():
	if player_rects.size() == 0 or player_path_follows.size() == 0:
		return
	
	# Check if the current player is already moving
	var current_tween = player_tweens[current_player_index]
	if is_moving and current_tween and current_tween.is_valid():
		return
	
	# Get current player's position
	var position = player_positions[current_player_index]
	
	# Calculate path offset for the current position (0-1 range)
	var target_offset = float(position - 1) / 25.0  # 26 positions, 0-25 index range
	
	# Get the PathFollow2D for the current player
	var path_follow = player_path_follows[current_player_index]
	
	# Start movement animation
	is_moving = true
	var tween = create_tween()
	tween.tween_property(path_follow, "progress_ratio", target_offset, 0.5)
	tween.tween_callback(func(): is_moving = false)
	
	# Store the tween for this player
	player_tweens[current_player_index] = tween
	
	print("Player ", current_player_index + 1, " moving to position ", position, " (path offset: ", target_offset, ")")
	
	# Update the player turn label
	player_turn_label.text = "Player " + str(current_player_index + 1) + "'s Turn"
	player_turn_label.add_theme_color_override("font_color", player_colors[current_player_index])

# Function to update a specific player's visual position without changing the current player's turn
func update_player_position_by_index(player_idx):
	if player_rects.size() == 0 or player_path_follows.size() == 0 or player_idx < 0 or player_idx >= player_rects.size():
		return
	
	# Get the specified player's position
	var position = player_positions[player_idx]
	
	# Calculate path offset for the position (0-1 range)
	var target_offset = float(position - 1) / 25.0  # 26 positions, 0-25 index range
	
	# Get the PathFollow2D for this player
	var path_follow = player_path_follows[player_idx]
	
	# Create a tween for this player's movement
	var tween = create_tween()
	tween.tween_property(path_follow, "progress_ratio", target_offset, 0.5)
	
	# Store the tween for this player
	player_tweens[player_idx] = tween
	
	print("Player ", player_idx + 1, " respawned to position ", position, " (path offset: ", target_offset, ")")

# Board configuration
var stone_positions = {
	1: {"type": "start", "safe": true},
	2: {"type": "normal", "name": "Stone1"},
	3: {"type": "frog", "name": "Frog1", "jump_to": 8},
	4: {"type": "dice", "name": "Dice1"},
	5: {"type": "normal", "name": "Stone2"},
	6: {"type": "duck", "name": "Duck1", "safe": true},
	7: {"type": "switch", "name": "Switch1"},
	8: {"type": "normal", "name": "Stone3"},
	9: {"type": "normal", "name": "Stone4"},
	10: {"type": "frog", "name": "Frog2", "jump_to": 14},
	11: {"type": "duck", "name": "Duck2", "safe": true},
	12: {"type": "normal", "name": "Stone5"},
	13: {"type": "checkpoint", "name": "CheckPoint", "safe": true},
	14: {"type": "normal", "name": "Stone6"},
	15: {"type": "switch", "name": "Switch2"},
	16: {"type": "frog", "name": "Frog3", "jump_to": 19},
	17: {"type": "duck", "name": "Duck3", "safe": true},
	18: {"type": "normal", "name": "Stone7"},
	19: {"type": "normal", "name": "Stone8"},
	20: {"type": "dice", "name": "Dice2"},
	21: {"type": "normal", "name": "Stone9"},
	22: {"type": "duck", "name": "Duck4", "safe": true},
	23: {"type": "normal", "name": "Stone10"},
	24: {"type": "duck", "name": "Duck5", "safe": true},
	25: {"type": "normal", "name": "Stone11"},
	26: {"type": "end", "name": "End"}
}

var current_checkpoint = 1  # Start position
var player_position = 1

# Enhanced stone effect handler
func process_stone_effect(position):
	var stone = stone_positions[position]
	match stone.type:
		"frog":
			var jump_to = stone.jump_to
			print("Player ", current_player_index + 1, " landed on a frog stone! Jumping to position ", jump_to)
			return jump_to
		"dice":
			print("Player ", current_player_index + 1, " landed on a dice stone! Rolling again...")
			# Add a small delay before rolling again
			await get_tree().create_timer(0.5).timeout
			
			# Store the current dice value to check if it was a brown face
			var was_brown_face = current_dice_value >= 4 and current_dice_value <= 6
			
			# Make sure we set player_move_completed to true before rolling again
			# This ensures any pending log movement from previous roll completes
			player_move_completed = true
			
			# If this was a brown face roll that landed on a dice stone,
			# we need to delay the log movement until all dice rolls are complete
			if was_brown_face:
				print("Delaying log movement until all dice rolls are complete")
				# Set the pending log movement flag to true
				pending_log_movement = true
			
			# Roll the dice again - this will trigger another player movement
			roll_dice()
			
			return position
		"checkpoint":
			player_checkpoints[current_player_index] = position
			print("Player ", current_player_index + 1, " reached checkpoint! New respawn point set to position ", position)
			return position
		_:
			return position

# Function to check if a position is safe from wood log
func is_safe_position(position):
	if position in stone_positions:
		return stone_positions[position].get("safe", false)
	return false

# Function to handle wood log collision for the current player
func handle_wood_log_collision():
	var current_pos = player_positions[current_player_index]
	if is_safe_position(current_pos):
		print("Player ", current_player_index + 1, " is safe on position ", current_pos, "!")
		return
	
	# Make sure checkpoint is updated if player is at or beyond position 13
	if player_positions[current_player_index] >= 13 and player_checkpoints[current_player_index] < 13:
		player_checkpoints[current_player_index] = 13
		print("Updating checkpoint to 13 for Player ", current_player_index + 1, " since they were at position ", player_positions[current_player_index])
	
	# Respawn at checkpoint or start
	print("Wood log hit! Player ", current_player_index + 1, "'s checkpoint is: ", player_checkpoints[current_player_index])
	player_positions[current_player_index] = player_checkpoints[current_player_index]
	print("Wood log hit! Player ", current_player_index + 1, " respawning at position ", player_positions[current_player_index])
	
	# Cancel any ongoing movement
	var current_tween = player_tweens[current_player_index]
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		is_moving = false
	
	# Update player visual position
	update_player_visual_position()

# Function to handle wood log collision for a specific player without changing turn order
func handle_wood_log_collision_for_player(player_idx):
	var current_pos = player_positions[player_idx]
	if is_safe_position(current_pos):
		print("Player ", player_idx + 1, " is safe on position ", current_pos, "!")
		return
	
	# Make sure checkpoint is updated if player is at or beyond position 13
	if player_positions[player_idx] >= 13 and player_checkpoints[player_idx] < 13:
		player_checkpoints[player_idx] = 13
		print("Updating checkpoint to 13 for Player ", player_idx + 1, " since they were at position ", player_positions[player_idx])
	
	# Respawn at checkpoint or start
	print("Wood log hit! Player ", player_idx + 1, "'s checkpoint is: ", player_checkpoints[player_idx])
	player_positions[player_idx] = player_checkpoints[player_idx]
	print("Wood log hit! Player ", player_idx + 1, " respawning at position ", player_positions[player_idx])
	
	# Cancel any ongoing movement for this player
	var player_tween = player_tweens[player_idx]
	if player_tween and player_tween.is_valid():
		player_tween.kill()
	
	# Update this player's visual position without changing the current player's turn
	update_player_position_by_index(player_idx)

# Add process function to handle continuous updates
func _process(delta):
	# Check for wood log collisions with all players
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	if wood_log_node and player_rects.size() > 0:
		# Update UI or game state based on wood log movement
		if wood_log_node.is_moving:
			# Disable dice button or show visual indicator that dice can't be rolled
			# This would be implemented by connecting to UI elements
			
			# Get the log position once for all collision checks
			var log_pos = wood_log_node.global_position
			
			# Check collision only for active players based on player_count
			for i in range(player_count):
				var player = player_rects[i]
				var player_pos = player_positions[i]
				
				# Simple collision detection - if wood log is moving and player is in unsafe position
				if not is_safe_position(player_pos):
					# Check if wood log is near player's vertical position
					var player_global_pos = player.global_position
					
					# Simple vertical collision check (adjust values as needed)
					if abs(log_pos.y - player_global_pos.y) < 100:
						# Handle collision for this player without changing the current_player_index
						# This ensures the turn order is preserved
						handle_wood_log_collision_for_player(i)

# Add pause button functionality
func _on_pause_button_pressed():
	if pause_menu:
		pause_menu.visible = true
		get_tree().paused = true
	else:
		print("Warning: Pause menu not available")
		# Still pause the game even if menu isn't available
		get_tree().paused = true

# Function to handle player movement on the board
func move_player(player_node, steps):
	# If player is already moving or wood log is moving, don't allow another move
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	if is_moving or (wood_log_node and wood_log_node.is_moving):
		print("Cannot move player while log is moving or player is already moving")
		return
	
	# Reset player movement completion flag at the start of movement
	player_move_completed = false
	
	var new_position = player_positions[current_player_index] + steps
	
	# Ensure position is within bounds
	if new_position > 26:  # 26 is the end position
		new_position = 26
		
		# Check if player reached the end
		if new_position == 26:
			print("Player ", current_player_index + 1, " reached the end!")
	
	# Check if player passed the checkpoint (position 13) during this move
	if player_positions[current_player_index] <= 13 and new_position > 13:
		player_checkpoints[current_player_index] = 13
		print("Player ", current_player_index + 1, " passed checkpoint! New respawn point set to position 13")
	
	player_positions[current_player_index] = new_position
	print("Player ", current_player_index + 1, " moved to position ", new_position)
	
	# Move player visually to the new position
	update_player_visual_position()
	
	# Wait for movement to complete before handling stone effects
	await get_tree().create_timer(0.6).timeout
	
	# Check if this is a dice stone before processing effects
	var is_dice_stone = false
	if new_position in stone_positions and stone_positions[new_position].type == "dice":
		is_dice_stone = true
		print("Player ", current_player_index + 1, " landed on a dice stone")
	
	# Handle stone effect at new position
	var after_effect_position = await process_stone_effect(new_position)
	if after_effect_position != new_position:
		player_positions[current_player_index] = after_effect_position
		update_player_visual_position()
		# Wait for any additional movement to complete
		await get_tree().create_timer(0.6).timeout
	
	# Signal that player movement is complete
	player_move_completed = true
	print("Player ", current_player_index + 1, " movement completed")
	
	# If a brown face was rolled and player did NOT land on a dice stone,
	# now it's safe to move the log
	if current_dice_value >= 4 and current_dice_value <= 6 and not is_dice_stone:
		print("Brown face rolled! Moving log now that player movement is complete...")
		move_log()
	# If there's a pending log movement from a previous brown face roll that landed on a dice stone
	elif pending_log_movement and not is_dice_stone:
		print("Executing pending log movement after all dice rolls are complete...")
		pending_log_movement = false
		move_log()
		# Wait for any additional movement to complete
		await get_tree().create_timer(0.6).timeout
	
	# If player didn't land on a dice stone, move to the next player's turn
	if not is_dice_stone:
		# Move to the next player's turn based on player_count
		current_player_index = (current_player_index + 1) % player_count
		print("Now it's Player ", current_player_index + 1, "'s turn")
		
		# Update the player turn label
		player_turn_label.text = "Player " + str(current_player_index + 1) + "'s Turn"
		player_turn_label.add_theme_color_override("font_color", player_colors[current_player_index])
		
		# Update the visual position for the new current player
		update_player_visual_position()
