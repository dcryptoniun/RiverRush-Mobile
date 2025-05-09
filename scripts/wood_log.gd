extends Node2D

# Signal for when log movement completes
signal movement_complete

# Variables for wood log movement
var is_moving = false
var speed = 800  # Speed of log movement in pixels per second
var screen_width = 0  # Will be updated in _ready() and _process()
var screen_height = 0  # Will be updated in _ready() and _process()
var direction = 1  # 1 for top to bottom, -1 for bottom to top

# Reference to the texture rect
@onready var texture_rect = $TextureRect

func _ready():
	# Initialize the wood log
	print("Wood log initialized")
	
	# Hide initially
	visible = false
	
	# Get screen dimensions for log movement
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y

# Function to start log movement
func start_movement(from_direction = 1):
	if is_moving:
		return
	
	is_moving = true
	direction = from_direction
	
	# Update screen dimensions to ensure accurate positioning
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y
	
	# Set fixed starting position at x:-132, y:-132
	position = Vector2(-132, -132)
	print("Log moving from fixed position x:-132, y:-132 downward")
	
	# Play wood rolling sound effect
	SoundManager.play_sfx("wood_rolling")
	
	# Make log visible
	visible = true

# Process function to handle log movement animation
func _process(delta):
	# Update screen dimensions in case of window resize
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y
	
	if is_moving and visible:
		# Always move log downward while keeping x-coordinate constant
		position.y += speed * delta
		
		# Check if log has moved off screen
		if position.y > screen_height + 50:
			# Log has moved off screen
			visible = false
			is_moving = false
			print("Log moved off screen (bottom)")
			# Reset position for next time
			position = Vector2(-132, -132)
			
			# Signal that the log movement is complete
			# This allows the game to know when to check for collisions
			movement_completed()

# Function to handle movement completion
func movement_completed():
	# This function can be connected to by the game board
	# to handle any post-movement logic
	print("Log movement complete")
	
	# Reset for next use
	await get_tree().create_timer(0.5).timeout
	# Ready for next movement
	position = Vector2(-132, -132)
	
	# Emit signal that movement is complete
	movement_complete.emit()
