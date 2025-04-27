extends Control

# Import required classes for GDPR consent handling
const ConsentInformation = preload("res://addons/AdmobPlugin/model/ConsentInformation.gd")
const ConsentRequestParameters = preload("res://addons/AdmobPlugin/model/ConsentRequestParameters.gd")

# We no longer need the option button reference since we're using separate buttons
# for each player count

# Reference to the AdMob node
var admob_node: Node

func _ready() -> void:
	# Get reference to the AdMob node
	admob_node = $Admob
	
	# Connect to AdMob signals
	if admob_node:
		# Connect to AdMob initialization and ad signals
		admob_node.connect("initialization_completed", _on_admob_initialization_completed)
		admob_node.connect("banner_ad_loaded", _on_banner_ad_loaded)
		admob_node.connect("banner_ad_failed_to_load", _on_banner_ad_failed_to_load)
		
		# Connect to consent-related signals
		admob_node.connect("consent_info_updated", _on_consent_info_updated)
		admob_node.connect("consent_info_update_failed", _on_consent_info_update_failed)
		admob_node.connect("consent_form_loaded", _on_consent_form_loaded)
		admob_node.connect("consent_form_dismissed", _on_consent_form_dismissed)
		admob_node.connect("consent_form_failed_to_load", _on_consent_form_failed_to_load)
		
		# Initialize AdMob
		admob_node.initialize()
		print("AdMob initialization started")
	else:
		print("AdMob node not found")

# Called when AdMob is initialized
func _on_admob_initialization_completed(status_data) -> void:
	print("AdMob initialization completed")
	
	# Check consent status first
	check_consent_status()
	
	# Banner ad will be loaded after consent is handled

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


# Start game with 2 players
func _on_start_button_2_pressed() -> void:
	start_game_with_player_count(2)

# Start game with 3 players
func _on_start_button_3_pressed() -> void:
	start_game_with_player_count(3)

# Start game with 4 players
func _on_start_button_4_pressed() -> void:
	start_game_with_player_count(4)

# Start game with 2 players (second player is AI)
func _on_start_button_ai_pressed() -> void:
	start_game_with_player_count(2, true)

# GDPR Consent handling functions

# Check the current consent status and take appropriate action
func check_consent_status() -> void:
	if admob_node:
		var consent_status = admob_node.get_consent_status()
		print("Current consent status: ", consent_status)
		
		match consent_status:
			ConsentInformation.ConsentStatus.UNKNOWN:
				# Need to update consent information
				print("Consent status unknown, updating consent info")
				update_consent_information()
				
			ConsentInformation.ConsentStatus.REQUIRED:
				# Consent is required, check if form is available
				print("Consent required, checking form availability")
				if admob_node.is_consent_form_available():
					show_consent_form()
				else:
					load_consent_form()
				
			ConsentInformation.ConsentStatus.NOT_REQUIRED:
				# Consent not required, load ads
				print("Consent not required, loading ads")
				load_ads()
				
			ConsentInformation.ConsentStatus.OBTAINED:
				# Consent already obtained, load ads
				print("Consent already obtained, loading ads")
				load_ads()

# Update consent information for EU users
func update_consent_information() -> void:
	if admob_node:
		# Create consent request parameters
		var params = ConsentRequestParameters.new()
		# For testing, you can set debug geography
		# params.set_debug_geography(ConsentRequestParameters.DebugGeography.DEBUG_GEOGRAPHY_EEA)
		
		# Update consent information
		admob_node.update_consent_info(params)
		print("Updating consent information")

# Load the consent form
func load_consent_form() -> void:
	if admob_node:
		admob_node.load_consent_form()
		print("Loading consent form")

# Show the consent form to the user
func show_consent_form() -> void:
	if admob_node:
		admob_node.show_consent_form()
		print("Showing consent form")

# Load ads after consent is handled
func load_ads() -> void:
	if admob_node:
		# Load banner ad
		admob_node.load_banner_ad()
		print("Loading banner ad")

# Consent signal handlers
func _on_consent_info_updated() -> void:
	print("Consent info updated")
	# Check consent status again after update
	check_consent_status()

# Called when consent info update fails
func _on_consent_info_update_failed(error_data) -> void:
	print("Consent info update failed: ", error_data)
	# Load ads anyway as fallback
	load_ads()

# Called when consent form is loaded
func _on_consent_form_loaded() -> void:
	print("Consent form loaded")
	# Show the consent form
	show_consent_form()

# Called when consent form is dismissed
func _on_consent_form_dismissed(error_data) -> void:
	print("Consent form dismissed")
	# Load ads after consent form is dismissed
	load_ads()

# Called when consent form fails to load
func _on_consent_form_failed_to_load(error_data) -> void:
	print("Consent form failed to load: ", error_data)
	# Load ads anyway as fallback
	load_ads()
