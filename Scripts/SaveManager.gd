extends Node

const SETTINGS_PATH = "user://settings.cfg"
const SAVE_FILE_PATH = "user://save.cfg"
const SAVE_FILE_PASS = "Godotzilla" # Change this in your game!!!

var save_slot_id := -1 # -1 means no save
var save_data := {
	"board_id": "",
	"board_data": {},
	"score": 0,
}

#region Settings

func _ready() -> void:
	var file := load_settings_file()
	
	VideoSettings.load_video_settings(file)
	SoundSettings.load_sound_settings(file)
	ControlsSettings.init_controls()
	ControlsSettings.load_mapping(file)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ResetControls"):
		InputMap.load_from_project_settings()
		var file := load_settings_file()
		file.erase_section("Input")
		save_settings_file(file)

func load_settings_file() -> ConfigFile:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		save_settings_file(file)
	return file
	
func save_settings_file(file: ConfigFile) -> void:
	file.save(SETTINGS_PATH)
	
#endregion

#region Save files
	
func load_save_data() -> Dictionary:
	var config_file := load_save_file()
	save_data = config_file.get_value(get_save_slot_section(), "data", {})
	return save_data
	
func store_save_data() -> void:
	var config_file := load_save_file()
	config_file.set_value(get_save_slot_section(), "data", save_data)
	store_save_file(config_file)
	
func load_save_file() -> ConfigFile:
	var file := ConfigFile.new()
	if file.load_encrypted_pass(SAVE_FILE_PATH, get_save_password()) != OK:
		store_save_file(file)
	return file
	
func store_save_file(file: ConfigFile) -> void:
	if save_slot_id >= 0:
		file.save_encrypted_pass(SAVE_FILE_PATH, get_save_password())
	
func set_save_slot(id: int) -> void:
	save_slot_id = id

func get_save_slot_section() -> String:
	return "save" + str(save_slot_id+1)
	
func get_save_password() -> String:
	# We tried to prevent other people from sending their
	# save files to other people
	# Like imagine if someone completed the game and sent other
	# people their save file
	# So we also use (hopefully) user-unique home directory
	return SAVE_FILE_PASS + OS.get_user_data_dir()

#endregion
