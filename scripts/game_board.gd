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
	Color(0.1, 0.9, 0.1, 0.8),  # Green (Player 2)
	Color(0.1, 0.1, 0.9, 0.8),  # Blue (Player 3)
	Color(0.9, 0.9, 0.1, 0.8)   # Yellow (Player 4)
]
var player_count = 2  # Default player count if not specified
var player_sprites = []  # Array to store all player sprite nodes
var player_positions = []  # Array to store positions of all players
var player_previous_positions = []  # Array to store previous positions of all players
var player_checkpoints = []  # Array to store checkpoints of all players
var player_path_follows = []  # Array to store PathFollow2D nodes for each player
var player_tweens = []  # Array to store tweens for each player
var bounce_tweens = []  # Array to store bounce animation tweens for each player
var current_player_index = 0  # Index of the current player
var dice_bg = null  # Reference to the dice background ColorRect
var player_textures = []  # Array to store player textures

# AI player variables
var ai_enabled = false  # Flag to indicate if AI is enabled for player 2
var ai_thinking_timer = null  # Timer for AI "thinking" delay

var stone_node_positions = {}  # Will store actual positions of stones in the scene
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
	
	# Initialize AI mode if enabled
	if has_meta("ai_enabled"):
		ai_enabled = get_meta("ai_enabled")
		print("AI mode enabled: ", ai_enabled)
	
	# Create AI thinking timer
	ai_thinking_timer = Timer.new()
	ai_thinking_timer.one_shot = true
	ai_thinking_timer.wait_time = 1.5  # AI will "think" for 1.5 seconds before moving
	ai_thinking_timer.connect("timeout", _on_ai_thinking_timer_timeout)
	add_child(ai_thinking_timer)
	
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
	
	# Using individual Path2D nodes for each player now
	
	# Connect to wood log movement complete signal
	var wood_log_node = get_node_or_null("WoodLog")
	if wood_log_node and not wood_log_node.is_connected("movement_complete", _on_wood_log_movement_complete):
		wood_log_node.movement_complete.connect(_on_wood_log_movement_complete)
	
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
		
		# Generate final random value with weighted probability
		# Regular faces (1-3) should have 60% probability
		# Brown faces (4-6) should have 40% probability
		var random_value = randf()
		if random_value < 0.6:
			# 60% chance for regular faces (1-3)
			current_dice_value = randi() % 3 + 1
		else:
			# 40% chance for brown faces (4-6)
			current_dice_value = randi() % 3 + 4
		
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
		move_player(player_sprites[current_player_index], steps)
		
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

# Function to load player textures
func _load_player_textures():
	# Load player textures from assets/players folder
	player_textures = [
		load("res://assets/players/red.png"),
		load("res://assets/players/blue.png"),
		load("res://assets/players/green.png"),
		load("res://assets/players/yellow.png")
	]

# Function to start bounce animation for a player sprite
func start_bounce_animation(player_index):
	# Make sure the player index is valid
	if player_index < 0 or player_index >= player_sprites.size():
		return
	
	# Get the player sprite
	var player_sprite = player_sprites[player_index]
	
	# Stop any existing bounce animation for this player
	stop_bounce_animation(player_index)
	
	# Create a new tween for the bounce animation
	var bounce_tween = create_tween()
	bounce_tween.set_loops() # Make the animation loop indefinitely
	
	# Set up the bounce animation
	# Move up
	bounce_tween.tween_property(player_sprite, "position:y", -10, 0.3)
	# Move down
	bounce_tween.tween_property(player_sprite, "position:y", 0, 0.3)
	
	# Store the bounce tween
	bounce_tweens[player_index] = bounce_tween

# Function to stop bounce animation for a player sprite
func stop_bounce_animation(player_index):
	# Make sure the player index is valid
	if player_index < 0 or player_index >= bounce_tweens.size():
		return
	
	# Check if there's an active bounce tween for this player
	var bounce_tween = bounce_tweens[player_index]
	if bounce_tween and bounce_tween.is_valid():
		# Stop the tween
		bounce_tween.kill()
		
		# Reset the sprite position
		player_sprites[player_index].position.y = 0

# Function to initialize players from the scene
func create_player():
	# Load player textures
	_load_player_textures()
	
	# Get reference to the player turn label and dice background in the scene
	dice_bg = get_node_or_null("MarginContainer/DiceContainer/DiceBG")
	
	
	# Set initial dice background color for player 1
	if dice_bg:
		dice_bg.color = player_colors[0]
	
	# Initialize arrays
	player_sprites = []
	player_path_follows = []
	player_tweens = []
	bounce_tweens = []
	player_positions = []
	player_previous_positions = []
	player_checkpoints = []
	
	# Define the color names for each player path
	var color_names = ["Red", "Green", "Blue", "Yellow"]
	
	# First, find and process all player nodes in the scene
	for i in range(color_names.size()):
		# Get the Path2D node for this player
		var path_name = color_names[i] + "Path2D"
		var path_node = get_node_or_null(path_name)
		
		if not path_node:
			print("Error: Path2D node '" + path_name + "' not found in scene")
			continue
		
		# Get the PathFollow2D node
		var path_follow = path_node.get_node_or_null("PathFollow2D")
		if not path_follow:
			print("Error: PathFollow2D node not found under '" + path_name + "'")
			continue
		
		# Get the Sprite2D node
		var player_sprite = path_follow.get_node_or_null("Sprite2D")
		if not player_sprite:
			print("Error: Sprite2D node not found under PathFollow2D")
			continue
		
		# Configure the PathFollow2D
		path_follow.loop = false  # Don't loop around the path
		path_follow.progress_ratio = 0.0  # Start at the beginning of the path
		
		# Only add active players to our arrays based on player_count
		if i < player_count:
			# Make sure this player is visible
			player_sprite.visible = true
			
			# Add player and PathFollow2D to our arrays
			player_sprites.append(player_sprite)
			player_path_follows.append(path_follow)
			
			# Initialize tween array with null values
			player_tweens.append(null)
			bounce_tweens.append(null)
			
			# Initialize player position, previous position and checkpoint
			player_positions.append(1)  # All players start at position 1
			player_previous_positions.append(1)  # All players start with previous position at position 1
			player_checkpoints.append(1)  # All players start with checkpoint at position 1
		else:
			# Hide players that exceed the player count
			player_sprite.visible = false
			print("Player " + str(i + 1) + " hidden as player_count is set to " + str(player_count))
	
	# Update the visual position of the current player
	update_player_visual_position()
	
	# Start bounce animation for the current player
	start_bounce_animation(current_player_index)

# Function to update player visual position based on current player's position
func update_player_visual_position():
	if player_sprites.size() == 0 or player_path_follows.size() == 0:
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
	
	
	# Update dice background color
	if dice_bg:
		dice_bg.color = player_colors[current_player_index]
	
	# Stop bounce animation for all players
	for i in range(player_sprites.size()):
		stop_bounce_animation(i)
	
	# Start bounce animation for the current player
	start_bounce_animation(current_player_index)

# Function to update a specific player's visual position without changing the current player's turn
func update_player_position_by_index(player_idx):
	if player_sprites.size() == 0 or player_path_follows.size() == 0 or player_idx < 0 or player_idx >= player_sprites.size():
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
		"switch":
			var previous_pos = player_previous_positions[current_player_index]
			print("Player ", current_player_index + 1, " landed on a switch stone! Going back to position ", previous_pos)
			return previous_pos
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
	if wood_log_node and player_sprites.size() > 0:
		# Update UI or game state based on wood log movement
		if wood_log_node.is_moving:
			# Disable dice button or show visual indicator that dice can't be rolled
			# This would be implemented by connecting to UI elements
			
			# Get the log position once for all collision checks
			var log_pos = wood_log_node.global_position
			
			# Check collision only for active players based on player_count
			for i in range(player_count):
				var player = player_sprites[i]
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

# AI thinking timer timeout - roll dice and move automatically
func _on_ai_thinking_timer_timeout() -> void:
	# AI automatically rolls the dice
	roll_dice()
	# The dice roll will trigger the movement in the roll_dice function
	
	# Re-enable the dice button after AI's turn
	var dice_button = get_node_or_null("%RollButton")
	if dice_button:
		dice_button.disabled = false

# Handle wood log movement completion
func _on_wood_log_movement_complete() -> void:
	print("Wood log movement complete signal received")
	
	# If we're waiting for player movement to complete, don't advance turn yet
	if not player_move_completed:
		print("Waiting for player movement to complete before advancing turn")
		return
	
	# Advance to the next player's turn
	current_player_index = (current_player_index + 1) % player_count
	print("Now it's Player ", current_player_index + 1, "'s turn")
	
	
	# Update dice background color
	if dice_bg:
		dice_bg.color = player_colors[current_player_index]
	
	# Check if it's AI player's turn (player 2 is index 1)
	if ai_enabled and current_player_index == 1:
		print("AI player is thinking...")
		# Add a small delay before AI makes its move to simulate "thinking"
		ai_thinking_timer.start()
		# Disable dice button while AI is thinking
		var dice_button = get_node_or_null("%RollButton")
		if dice_button:
			dice_button.disabled = true
	# Make sure human players can interact with the dice button
	else:
		var dice_button = get_node_or_null("%RollButton")
		if dice_button:
			dice_button.disabled = false
			
	# Update the visual position for the new current player
	update_player_visual_position()

# Function to handle player movement on the board
func move_player(player_node, steps):
	# If player is already moving or wood log is moving, don't allow another move
	var wood_log_node = get_node_or_null("/root/GameBoard/WoodLog")
	if is_moving or (wood_log_node and wood_log_node.is_moving):
		print("Cannot move player while log is moving or player is already moving")
		return
	
	# Reset player movement completion flag at the start of movement
	player_move_completed = false
	
	# Store the current position as previous position before moving
	player_previous_positions[current_player_index] = player_positions[current_player_index]
	
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
		# Don't advance to next player yet - wait for log movement to complete
		# The _on_wood_log_movement_complete signal handler will handle turn advancement
		return
	# If there's a pending log movement from a previous brown face roll that landed on a dice stone
	elif pending_log_movement and not is_dice_stone:
		print("Executing pending log movement after all dice rolls are complete...")
		pending_log_movement = false
		move_log()
		# Don't advance to next player yet - wait for log movement to complete
		# The _on_wood_log_movement_complete signal handler will handle turn advancement
		return
	
	# If player didn't land on a dice stone, move to the next player's turn
	if not is_dice_stone:
		# Move to the next player's turn based on player_count
		current_player_index = (current_player_index + 1) % player_count
		print("Now it's Player ", current_player_index + 1, "'s turn")
		
		
		# Update dice background color
		if dice_bg:
			dice_bg.color = player_colors[current_player_index]
		
		# Check if it's AI player's turn (player 2 is index 1)
		if ai_enabled and current_player_index == 1:
			print("AI player is thinking...")
			# Add a small delay before AI makes its move to simulate "thinking"
			ai_thinking_timer.start()
			# Disable dice button while AI is thinking
			var dice_button = get_node_or_null("%RollButton")
			if dice_button:
				dice_button.disabled = true
		# Make sure human players can interact with the dice button
		else:
			var dice_button = get_node_or_null("%RollButton")
			if dice_button:
				dice_button.disabled = false
		
		# Update the visual position for the new current player
		update_player_visual_position()
