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

# Variables for player
var player_rect = null
var stone_node_positions = {}  # Will store actual positions of stones in the scene
var path_follow = null  # Reference to PathFollow2D for player movement
var current_path_offset = 0.0  # Current position on the path
var is_moving = false  # Flag to track if player is currently moving
var move_tween = null  # Reference to the tween for player movement

func _ready():
	# Initialize the game board
	print("Game board initialized")
	
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
	
	# Get reference to PathFollow2D for player movement
	path_follow = $Path2D/PathFollow2D
	
	# Store positions of all stones for player movement
	store_stone_positions()
	
	# Create player placeholder
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
		print("Dice rolled: ", current_dice_value)
		
		# Move player based on dice value (1-3 for regular faces)
		var steps = current_dice_value
		if steps > 3:
			steps = steps - 3  # Convert 4,5,6 to 1,2,3 for brown faces
		
		# Move player - wood log movement will be triggered after player movement completes
		move_player(player_rect, steps)
		
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

# Function to create player placeholder
func create_player():
	# Create a ColorRect as player placeholder
	player_rect = ColorRect.new()
	player_rect.color = Color(0.9, 0.1, 0.1, 0.8)  # Red color with some transparency
	player_rect.custom_minimum_size = Vector2(30, 30)  # Size of player
	
	# Add to PathFollow2D instead of directly to the scene
	path_follow.add_child(player_rect)
	
	# Center the player on the path
	player_rect.position = Vector2(-player_rect.custom_minimum_size.x/2, -player_rect.custom_minimum_size.y/2)
	
	# Set initial position (start position)
	player_position = 1  # Start at position 1
	update_player_visual_position()

# Function to update player visual position based on current player_position
func update_player_visual_position():
	if not player_rect or not path_follow:
		return
	
	if is_moving and move_tween and move_tween.is_valid():
		return
	
	# Calculate path offset for the current position (0-1 range)
	var target_offset = float(player_position - 1) / 25.0  # 26 positions, 0-25 index range
	
	# Start movement animation
	is_moving = true
	move_tween = create_tween()
	move_tween.tween_property(path_follow, "progress_ratio", target_offset, 0.5)
	move_tween.tween_callback(func(): is_moving = false)
	
	print("Player moving to position ", player_position, " (path offset: ", target_offset, ")")

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
			print("Frog stone! Jumping to position ", jump_to)
			return jump_to
		"dice":
			print("Dice stone! Rolling again...")
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
			current_checkpoint = position
			print("Checkpoint reached! New respawn point set to position ", position)
			return position
		_:
			return position

# Function to check if current position is safe from wood log
func is_safe_position(position):
	if position in stone_positions:
		return stone_positions[position].get("safe", false)
	return false

# Function to handle wood log collision
func handle_wood_log_collision():
	var current_pos = player_position
	if is_safe_position(current_pos):
		print("Safe on position ", current_pos, "!")
		return
	
	# Make sure checkpoint is updated if player is at or beyond position 13
	if player_position >= 13 and current_checkpoint < 13:
		current_checkpoint = 13
		print("Updating checkpoint to 13 since player was at position ", player_position)
	
	# Respawn at checkpoint or start
	print("Wood log hit! Current checkpoint is: ", current_checkpoint)
	player_position = current_checkpoint
	print("Wood log hit! Respawning at position ", player_position)
	
	# Cancel any ongoing movement
	if move_tween and move_tween.is_valid():
		move_tween.kill()
		is_moving = false
	
	# Update player visual position
	update_player_visual_position()

# Add process function to handle continuous updates
func _process(delta):
	# Check for wood log collisions with player
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	if wood_log_node and player_rect:
		# Update UI or game state based on wood log movement
		if wood_log_node.is_moving:
			# Disable dice button or show visual indicator that dice can't be rolled
			# This would be implemented by connecting to UI elements
			
			# Simple collision detection - if wood log is moving and player is in unsafe position
			if not is_safe_position(player_position):
				# Check if wood log is near player's vertical position
				var log_pos = wood_log_node.global_position
				var player_pos = player_rect.global_position
				
				# Simple vertical collision check (adjust values as needed)
				if abs(log_pos.y - player_pos.y) < 100:
					handle_wood_log_collision()

# Function to handle player movement on the board
func move_player(player_node, steps):
	# If player is already moving or wood log is moving, don't allow another move
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	if is_moving or (wood_log_node and wood_log_node.is_moving):
		print("Cannot move player while log is moving or player is already moving")
		return
	
	# Reset player movement completion flag at the start of movement
	player_move_completed = false
	
	var new_position = player_position + steps
	
	# Ensure position is within bounds
	if new_position > 26:  # 26 is the end position
		new_position = 26
	
	# Check if player passed the checkpoint (position 13) during this move
	if player_position <= 13 and new_position > 13:
		current_checkpoint = 13
		print("Passed checkpoint! New respawn point set to position 13")
	
	player_position = new_position
	print("Player moved to position ", player_position)
	
	# Move player visually to the new position
	update_player_visual_position()
	
	# Wait for movement to complete before handling stone effects
	await get_tree().create_timer(0.6).timeout
	
	# Check if this is a dice stone before processing effects
	var is_dice_stone = false
	if new_position in stone_positions and stone_positions[new_position].type == "dice":
		is_dice_stone = true
		print("Player landed on a dice stone")
	
	# Handle stone effect at new position
	var after_effect_position = await process_stone_effect(new_position)
	if after_effect_position != new_position:
		player_position = after_effect_position
		update_player_visual_position()
		# Wait for any additional movement to complete
		await get_tree().create_timer(0.6).timeout
	
	# Signal that player movement is complete
	player_move_completed = true
	print("Player movement completed")
	
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
