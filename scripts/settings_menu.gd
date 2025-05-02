extends Control

# Settings Menu for Beaver Run
# Handles audio settings UI and interactions with SoundManager

# UI References
@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MasterVolume/HSlider
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SFXVolume/HSlider
@onready var ambient_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/AmbientVolume/HSlider

@onready var master_mute_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/MasterVolume/MuteButton
@onready var music_mute_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/MusicVolume/MuteButton
@onready var sfx_mute_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/SFXVolume/MuteButton
@onready var ambient_mute_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/AmbientVolume/MuteButton

# Config file for saving settings
const CONFIG_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# Default settings values
const DEFAULT_MASTER_VOLUME = 1.0
const DEFAULT_MUSIC_VOLUME = 0.6
const DEFAULT_SFX_VOLUME = 1.0
const DEFAULT_AMBIENT_VOLUME = 0.2

func _ready():
	# Load saved settings
	load_settings()
	
	# Initialize UI with current values
	master_slider.value = SoundManager.master_volume
	music_slider.value = SoundManager.music_volume
	sfx_slider.value = SoundManager.sfx_volume
	ambient_slider.value = SoundManager.ambient_volume
	
	# Update mute button appearances
	update_mute_button(master_mute_btn, AudioServer.is_bus_mute(SoundManager.MASTER_BUS))
	update_mute_button(music_mute_btn, AudioServer.is_bus_mute(SoundManager.MUSIC_BUS))
	update_mute_button(sfx_mute_btn, AudioServer.is_bus_mute(SoundManager.SFX_BUS))
	update_mute_button(ambient_mute_btn, AudioServer.is_bus_mute(SoundManager.SFX_BUS))
	
	# Connect signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ambient_slider.value_changed.connect(_on_ambient_volume_changed)
	
	master_mute_btn.pressed.connect(_on_master_mute_pressed)
	music_mute_btn.pressed.connect(_on_music_mute_pressed)
	sfx_mute_btn.pressed.connect(_on_sfx_mute_pressed)
	ambient_mute_btn.pressed.connect(_on_ambient_mute_pressed)

# Load settings from config file
func load_settings():
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK:
		# If file doesn't exist, use default values from SoundManager
		return
	
	# Get saved volume values or use defaults
	var master_vol = config.get_value("audio", "master_volume", SoundManager.master_volume)
	var music_vol = config.get_value("audio", "music_volume", SoundManager.music_volume)
	var sfx_vol = config.get_value("audio", "sfx_volume", SoundManager.sfx_volume)
	var ambient_vol = config.get_value("audio", "ambient_volume", SoundManager.ambient_volume)
	
	# Apply saved settings
	SoundManager.set_master_volume(master_vol)
	SoundManager.set_music_volume(music_vol)
	SoundManager.set_sfx_volume(sfx_vol)
	SoundManager.set_ambient_volume(ambient_vol)
	
	# Apply saved mute states
	var master_mute = config.get_value("audio", "master_mute", false)
	var music_mute = config.get_value("audio", "music_mute", false)
	var sfx_mute = config.get_value("audio", "sfx_mute", false)
	
	AudioServer.set_bus_mute(SoundManager.MASTER_BUS, master_mute)
	AudioServer.set_bus_mute(SoundManager.MUSIC_BUS, music_mute)
	AudioServer.set_bus_mute(SoundManager.SFX_BUS, sfx_mute)

# Save settings to config file
func save_settings():
	# Save volume values
	config.set_value("audio", "master_volume", SoundManager.master_volume)
	config.set_value("audio", "music_volume", SoundManager.music_volume)
	config.set_value("audio", "sfx_volume", SoundManager.sfx_volume)
	config.set_value("audio", "ambient_volume", SoundManager.ambient_volume)
	
	# Save mute states
	config.set_value("audio", "master_mute", AudioServer.is_bus_mute(SoundManager.MASTER_BUS))
	config.set_value("audio", "music_mute", AudioServer.is_bus_mute(SoundManager.MUSIC_BUS))
	config.set_value("audio", "sfx_mute", AudioServer.is_bus_mute(SoundManager.SFX_BUS))
	
	# Save to file
	config.save(CONFIG_FILE_PATH)

# Update mute button appearance based on mute state
func update_mute_button(button: Button, is_muted: bool):
	if is_muted:
		button.text = "Unmute"
	else:
		button.text = "Mute"

# Signal handlers
func _on_master_volume_changed(value: float):
	SoundManager.set_master_volume(value)
	save_settings()


func _on_music_volume_changed(value: float):
	SoundManager.set_music_volume(value)
	save_settings()


func _on_sfx_volume_changed(value: float):
	SoundManager.set_sfx_volume(value)
	save_settings()


func _on_master_mute_pressed():
	# Play UI sound effect
	SoundManager.play_sfx("ui")
	var is_muted = SoundManager.toggle_mute_master()
	update_mute_button(master_mute_btn, is_muted)
	save_settings()


func _on_music_mute_pressed():
	# Play UI sound effect
	SoundManager.play_sfx("ui")
	var is_muted = SoundManager.toggle_mute_music()
	update_mute_button(music_mute_btn, is_muted)
	save_settings()


func _on_sfx_mute_pressed():
	# Play UI sound effect
	SoundManager.play_sfx("ui")
	var is_muted = SoundManager.toggle_mute_sfx()
	update_mute_button(sfx_mute_btn, is_muted)
	# Also update ambient mute button since they share the same bus
	update_mute_button(ambient_mute_btn, is_muted)
	save_settings()


func _on_ambient_volume_changed(value: float):
	SoundManager.set_ambient_volume(value)
	save_settings()


func _on_ambient_mute_pressed():
	# Play UI sound effect
	SoundManager.play_sfx("ui")
	var is_muted = SoundManager.toggle_mute_sfx()
	# Update both SFX and ambient mute buttons since they share the same bus
	update_mute_button(sfx_mute_btn, is_muted)
	update_mute_button(ambient_mute_btn, is_muted)
	save_settings()


func _on_reset_button_pressed():
	# Play UI sound effect
	SoundManager.play_sfx("ui")
	
	# Reset all values to defaults
	SoundManager.set_master_volume(DEFAULT_MASTER_VOLUME)
	SoundManager.set_music_volume(DEFAULT_MUSIC_VOLUME)
	SoundManager.set_sfx_volume(DEFAULT_SFX_VOLUME)
	SoundManager.set_ambient_volume(DEFAULT_AMBIENT_VOLUME)
	
	# Unmute all audio buses
	AudioServer.set_bus_mute(SoundManager.MASTER_BUS, false)
	AudioServer.set_bus_mute(SoundManager.MUSIC_BUS, false)
	AudioServer.set_bus_mute(SoundManager.SFX_BUS, false)
	
	# Update UI
	master_slider.value = DEFAULT_MASTER_VOLUME
	music_slider.value = DEFAULT_MUSIC_VOLUME
	sfx_slider.value = DEFAULT_SFX_VOLUME
	ambient_slider.value = DEFAULT_AMBIENT_VOLUME
	
	update_mute_button(master_mute_btn, false)
	update_mute_button(music_mute_btn, false)
	update_mute_button(sfx_mute_btn, false)
	update_mute_button(ambient_mute_btn, false)
	
	# Save the default settings
	save_settings()


func _on_back_button_pressed():
	# Play UI sound effect
	SoundManager.play_sfx("ui")
	# Return to previous scene
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
