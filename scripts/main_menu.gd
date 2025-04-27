extends Control

# We no longer need the option button reference since we're using separate buttons
# for each player count

# Reference to the AdMob node
var admob_node: Node

func _ready() -> void:
	# Get reference to the AdMob node
	admob_node = $Admob
	
	# Connect to AdMob signals
	if admob_node:
		admob_node.connect("initialization_completed", _on_admob_initialization_completed)
		admob_node.connect("banner_ad_loaded", _on_banner_ad_loaded)
		admob_node.connect("banner_ad_failed_to_load", _on_banner_ad_failed_to_load)
		
		# Initialize AdMob
		admob_node.initialize()
		print("AdMob initialization started")
	else:
		print("AdMob node not found")

# Called when AdMob is initialized
func _on_admob_initialization_completed(status_data) -> void:
	print("AdMob initialization completed")
	
	# Load banner ad - the plugin handles creating the ad request internally
	admob_node.load_banner_ad()

# Called when banner ad is loaded successfully
func _on_banner_ad_loaded(ad_id: String) -> void:
	print("Banner ad loaded successfully: " + ad_id)
	
	# Show the banner ad
	admob_node.show_banner_ad()

# Called when banner ad fails to load
func _on_banner_ad_failed_to_load(ad_id: String, error_data) -> void:
	print("Banner ad failed to load: " + ad_id)
	print("Error: " + str(error_data))

# Helper function to start the game with a specific player count
func start_game_with_player_count(player_count: int, ai_enabled: bool = false) -> void:
	await RenderingServer.frame_post_draw
	
	# Hide banner ad before transitioning to game scene
	if admob_node:
		admob_node.hide_banner_ad()
		print("Banner ad hidden before starting game")
	
	# Create the game scene and set the player count parameter
	var game_scene = load("res://scenes/game_board.tscn").instantiate()
	# Set player_count directly as a property
	game_scene.player_count = player_count
	# Set AI mode for player 2 if enabled
	game_scene.ai_enabled = ai_enabled
	
	# Get the current scene to remove it later
	var current_scene = get_tree().current_scene
	
	# Add the new scene to the tree
	get_tree().root.add_child(game_scene)
	
	# Set the new scene as current
	get_tree().current_scene = game_scene
	
	# Remove the old scene
	get_tree().root.remove_child(current_scene)
	current_scene.queue_free()
	
	print("Starting game with ", player_count, " players", ", AI enabled: ", ai_enabled)


# Start game with 2 players (second player is AI)
func _on_start_button_2_pressed() -> void:
	start_game_with_player_count(2, true)

# Start game with 3 players
func _on_start_button_3_pressed() -> void:
	start_game_with_player_count(3)

# Start game with 4 players
func _on_start_button_4_pressed() -> void:
	start_game_with_player_count(4)

# Legacy function for backward compatibility if needed
func _on_start_button_pressed() -> void:
	# Default to 2 players if the old start button is still in the scene
	start_game_with_player_count(2, true)
