extends Control

# This script manages the game board functionality
# It ensures the board stays in position regardless of screen size

# Variables for dice rolling
var current_dice_value = 1
var dice_images = []
var dice_display = null
var is_rolling = false

# Variables for wood log
var wood_log_scene = preload("res://scenes/wood_log.tscn")
var wood_log = null
var log_direction = 1  # 1 for right to left, -1 for left to right

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

# Function to handle player movement on the board
func move_player(player_node, steps):
	# This function will be implemented when player movement is added
	pass

# Function to handle wood log movement
func move_log():
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
	if is_rolling:
		return
		
	is_rolling = true
	
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
		
		# Check if a brown face was rolled (values 4, 5, 6 correspond to 1_b, 2_b, 3_b)
		if current_dice_value >= 4 and current_dice_value <= 6:
			print("Brown face rolled! Moving log...")
			move_log()
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
