extends Node

# Sound Manager for Beaver Run
# Handles background music and sound effects

# Audio buses
const MASTER_BUS = 0
const MUSIC_BUS = 1
const SFX_BUS = 2

# Audio players
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer  # Player for ambient sounds like river
var sfx_players: Array[AudioStreamPlayer] = []
var num_sfx_players = 5  # Number of sound effect players to create for pooling

# Audio resources
var music_tracks = {}
var sound_effects = {}
var ambient_sounds = {}  # Dictionary for ambient sounds

# Volume settings
var master_volume: float = 1.0
var music_volume: float = 0.6  # Reduced default music volume
var sfx_volume: float = 1.0

func _ready():
	# Initialize audio players
	initialize_audio_players()
	
	# Load audio resources
	load_audio_resources()
	
	# Start playing background music
	play_music("background")

# Initialize audio players for music and sound effects
func initialize_audio_players():
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_volume)
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS  # Continue playing during pause
	add_child(music_player)
	
	# Create ambient sound player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "SFX"
	ambient_player.volume_db = linear_to_db(sfx_volume)
	ambient_player.process_mode = Node.PROCESS_MODE_ALWAYS  # Continue playing during pause
	add_child(ambient_player)
	
	# Create pool of sound effect players
	for i in range(num_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_player.volume_db = linear_to_db(sfx_volume)
		sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS  # Continue playing during pause
		sfx_players.append(sfx_player)
		add_child(sfx_player)

# Load all audio resources
func load_audio_resources():
	# Load music tracks
	music_tracks["background"] = load("res://assets/SFX/awesomeness.wav")
	
	# Load sound effects
	sound_effects["swipe"] = load("res://assets/SFX/Swipe.mp3")
	sound_effects["ui"] = load("res://assets/SFX/ui.mp3")
	sound_effects["dice_roll"] = load("res://assets/SFX/rolling_dice_sfx.mp3")
	sound_effects["wood_rolling"] = load("res://assets/SFX/Wood Rolling.mp3")
	
	# Load ambient sounds
	ambient_sounds["river"] = load("res://assets/SFX/RiverSoundEffect.mp3")
	
	# Start playing ambient river sound
	play_ambient("river")

# Play background music
func play_music(track_name: String):
	if not music_tracks.has(track_name):
		push_error("Music track '" + track_name + "' not found")
		return
	
	# Set the music stream
	music_player.stream = music_tracks[track_name]
	
	# Loop the music
	music_player.finished.connect(_on_music_finished)
	
	# Play the music
	music_player.play()

# Handle music loop when finished
func _on_music_finished():
	# Disconnect the signal to avoid multiple connections
	if music_player.is_connected("finished", _on_music_finished):
		music_player.finished.disconnect(_on_music_finished)
	
	# Restart the music
	music_player.play()
	
	# Reconnect the signal
	music_player.finished.connect(_on_music_finished)

# Play a sound effect
func play_sfx(sfx_name: String):
	if not sound_effects.has(sfx_name):
		push_error("Sound effect '" + sfx_name + "' not found")
		return
	
	# Find an available sound effect player
	for player in sfx_players:
		if not player.playing:
			# Set the sound effect stream
			player.stream = sound_effects[sfx_name]
			
			# Play the sound effect
			player.play()
			return
	
	# If all players are busy, use the first one (oldest playing sound will be replaced)
	sfx_players[0].stream = sound_effects[sfx_name]
	sfx_players[0].play()

# Stop all sound effects
func stop_all_sfx():
	for player in sfx_players:
		player.stop()

# Stop background music
func stop_music():
	if music_player.is_connected("finished", _on_music_finished):
		music_player.finished.disconnect(_on_music_finished)
	music_player.stop()

# Set master volume (0.0 to 1.0)
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(master_volume))

# Set music volume (0.0 to 1.0)
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(music_volume))
	music_player.volume_db = linear_to_db(music_volume)

# Set sound effects volume (0.0 to 1.0)
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(sfx_volume))
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)
	ambient_player.volume_db = linear_to_db(sfx_volume)

# Mute/unmute master audio
func toggle_mute_master():
	AudioServer.set_bus_mute(MASTER_BUS, !AudioServer.is_bus_mute(MASTER_BUS))
	return AudioServer.is_bus_mute(MASTER_BUS)

# Mute/unmute music
func toggle_mute_music():
	AudioServer.set_bus_mute(MUSIC_BUS, !AudioServer.is_bus_mute(MUSIC_BUS))
	return AudioServer.is_bus_mute(MUSIC_BUS)

# Mute/unmute sound effects
func toggle_mute_sfx():
	AudioServer.set_bus_mute(SFX_BUS, !AudioServer.is_bus_mute(SFX_BUS))
	return AudioServer.is_bus_mute(SFX_BUS)

# Play ambient sound on loop
func play_ambient(ambient_name: String):
	if not ambient_sounds.has(ambient_name):
		push_error("Ambient sound '" + ambient_name + "' not found")
		return
	
	# Set the ambient sound stream
	ambient_player.stream = ambient_sounds[ambient_name]
	
	# Enable looping
	ambient_player.stream.loop = true
	
	# Set very low volume for river sound specifically
	if ambient_name == "river":
		ambient_player.volume_db = linear_to_db(0.2)  # Very minimal volume for river
	
	# Play the ambient sound
	ambient_player.play()

# Stop ambient sound
func stop_ambient():
	ambient_player.stop()
