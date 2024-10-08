class_name VideoSettings
extends "res://Scripts/MainMenu/Menu.gd"

# Section in the save file
const SECTION := "Video"
const RESOLUTIONS := [1, 2, 3, 4, -1]

@export var include_widescreen := true
var current_resolution := 2

func _ready() -> void:
	super._ready()
	var widescreen_node := $Widescreen
	
	if not include_widescreen:
		options.erase(widescreen_node)
		widescreen_node.queue_free()
		$Exit.position.y -= 24
		
	Global.fullscreen_changed.connect(func(flag: bool) -> void:
		if flag:
			$Resolution.text = "resolution: full screen"
		else:
			current_resolution = min(3, current_resolution)
			update_resolution()
		)
		
	var file := SaveManager.load_settings_file()
	widescreen_node.text = "wide screen: " + \
		("on" if file.get_value(SECTION, "widescreen", false) else "off")
	current_resolution = file.get_value(SECTION, "resolution", 2)
	update_resolution_text()
		
func menu_exit() -> void:
	save_video_settings()

func menu_select(id: int) -> void:
	if id == options.size() - 1:
		main_menu.set_menu($"../Settings")

func _process(_delta: float) -> void:
	match main_menu.selector_option:
		0: # Resolution
			if Input.is_action_just_pressed("Left"):
				current_resolution = max(current_resolution - 1, 0)
				update_resolution()
				
			if Input.is_action_just_pressed("Right"):
				current_resolution = min(current_resolution + 1, \
					RESOLUTIONS.size() - 1)
				update_resolution()
		1: # Wide screen
			if not include_widescreen:
				return
			
			if Input.is_action_just_pressed("Left"):
				$Widescreen.text = "wide screen: off"
				Global.use_widescreen(false)
				update_resolution()
				
			if Input.is_action_just_pressed("Right"):
				$Widescreen.text = "wide screen: on"
				Global.use_widescreen(true)
				update_resolution()

func update_resolution_text() -> void:
	if RESOLUTIONS[current_resolution] == -1:
		$Resolution.text = "resolution: full screen"
	else:
		$Resolution.text = "resolution: x" + str(RESOLUTIONS[current_resolution])

func update_resolution() -> void:
	update_resolution_text()
	
	Global.use_fullscreen(RESOLUTIONS[current_resolution] == -1)
	if Global.is_fullscreen():
		return
		
	get_window().set_size(Global.get_content_size() * RESOLUTIONS[current_resolution])
	
func save_video_settings() -> void:
	var file := SaveManager.load_settings_file()
	file.set_value(SECTION, "widescreen", Global.is_widescreen())
	file.set_value(SECTION, "fullscreen", Global.is_fullscreen())
	file.set_value(SECTION, "resolution", current_resolution)
	SaveManager.save_settings_file(file)
	
static func load_video_settings(file: ConfigFile) -> void:
	var resolution: int = file.get_value("Video", "resolution", 2)
	var window := Global.get_window()
	
	Global.use_widescreen(file.get_value("Video", "widescreen", false))
	Global.use_fullscreen(file.get_value("Video", "fullscreen", false))
	window.size = Global.get_content_size() * RESOLUTIONS[resolution]
	
	await Global.get_tree().process_frame
	window.move_to_center()
