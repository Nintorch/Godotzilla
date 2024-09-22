class_name SoundSettings
extends "res://Scripts/MainMenu/Menu.gd"

# Section in the save file
const SECTION = "Sound"

const SFX_BUS = 1
const MUSIC_BUS = 2

@onready var sfx_test: AudioStreamPlayer = $SFXTest
var sfx_volume := 100
var music_volume := 100

func _ready() -> void:
	super._ready()
	var file := SaveManager.load_settings_file()
	sfx_volume = file.get_value(SECTION, "sfx", 100)
	$SFXVolume.text = "sfx volume:   " + str(sfx_volume)
	music_volume = file.get_value(SECTION, "music", 100)
	$MusicVolume.text = "music volume: " + str(music_volume)

func menu_select(id: int) -> void:
	if id == 2:
		main_menu.set_menu(%Settings)
		
func menu_exit() -> void:
	save_sound_settings()

func _process(_delta: float) -> void:
	match main_menu.selector_option:
		0: # SFX volume
			if Input.is_action_just_pressed("Left"):
				sfx_volume = max(sfx_volume - 10, 0)
				update_sfx_volume()
				
			if Input.is_action_just_pressed("Right"):
				sfx_volume = min(sfx_volume + 10, 100)
				update_sfx_volume()
		1: # Music volume
			if Input.is_action_just_pressed("Left"):
				music_volume = max(music_volume - 10, 0)
				update_music_volume()
				
			if Input.is_action_just_pressed("Right"):
				music_volume = min(music_volume + 10, 100)
				update_music_volume()
				
func update_sfx_volume() -> void:
	$SFXVolume.text = "sfx volume:   " + str(sfx_volume)
	AudioServer.set_bus_volume_db(SFX_BUS,
		SoundSettings.volume_db_from_save(sfx_volume))
	sfx_test.bus = "SFX"
	sfx_test.play()
	
func update_music_volume() -> void:
	$MusicVolume.text = "music volume: " + str(music_volume)
	AudioServer.set_bus_volume_db(MUSIC_BUS,
		SoundSettings.volume_db_from_save(music_volume))
	sfx_test.bus = "Music"
	sfx_test.play()

func save_sound_settings() -> void:
	var file := SaveManager.load_settings_file()
	file.set_value(SECTION, "sfx", sfx_volume)
	file.set_value(SECTION, "music", music_volume)
	Global.save_settings_file(file)
	
static func load_sound_settings(file: ConfigFile) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS,
		volume_db_from_save(file.get_value(SECTION, "sfx", 100)))
	AudioServer.set_bus_volume_db(MUSIC_BUS,
		volume_db_from_save(file.get_value(SECTION, "music", 100)))

static func volume_db_from_save(value: int) -> int:
	return roundi((value - 100) * 0.8)
