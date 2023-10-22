extends Node

const SETTINGS_PATH = "user://settings.cfg"

var main: Node2D
var fading := false # set in Main.gd

var music: AudioStreamPlayer
var player: GameCharacter
var playing_levels: Array[PackedScene] = []
var board

signal widescreen_changed
signal fullscreen_changed(flag: bool) # only through use_fullscreen()
signal fade_end
signal scene_changed(from: Node, to: Node)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_settings()
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ResetControls"):
		InputMap.load_from_project_settings()
		var file = load_settings_file()
		file.erase_section("Input")
		save_settings_file(file)
		
	if Input.is_action_just_pressed("FullScreen"):
		use_fullscreen(not is_fullscreen())

func get_default_resolution() -> Vector2i:
	return Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
		)

func use_widescreen(flag: bool) -> void:
	var size = get_default_resolution()
	if flag:
		size.x = ProjectSettings.get_setting(
			"display/window/size/viewport_width_widescreen")
	get_tree().get_root().content_scale_size = size
	widescreen_changed.emit()
	
func is_widescreen() -> bool:
	return get_content_size().x > get_default_resolution().x
	
func use_fullscreen(flag: bool) -> void:
	const FULLSCREEN = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if flag and not is_fullscreen():
		DisplayServer.window_set_mode(FULLSCREEN)
		fullscreen_changed.emit(true)
	elif not flag and is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_changed.emit(false)
		
func is_fullscreen() -> bool:
	const FULLSCREEN = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	return DisplayServer.window_get_mode() == FULLSCREEN
	
func get_content_size() -> Vector2i:
	return get_tree().get_root().content_scale_size
	
func get_next_level() -> PackedScene:
	if playing_levels.size() == 0:
		return null
	return playing_levels.pop_front()

func any_action_button_pressed() -> bool:
	for action in ["B", "A", "Select", "Start"]:
		if Input.is_action_just_pressed(action):
			return true
	return false

func get_boards() -> Array[BoardDescription]:
	return main.boards
	
##region Save files

func load_game_settings() -> void:
	var file = load_settings_file()
	
	VideoSettings.load_video_settings(file)
	SoundSettings.load_sound_settings(file)
	ControlsSettings.load_mapping(file)

func load_settings_file() -> ConfigFile:
	var file = ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		file.save(SETTINGS_PATH)
	return file
	
func save_settings_file(file: ConfigFile) -> void:
	file.save(SETTINGS_PATH)
	
##endregion
	
##region Scene changing

func change_scene_node(node: Node, free = true) -> void:
	var curscene_parent = main.get_node("CurrentScene")
	var curscene = curscene_parent.get_child(0)
	
	curscene_parent.remove_child(curscene)
	if free:
		curscene.queue_free()
	curscene_parent.add_child(node)
	
	scene_changed.emit(curscene, node)
	
func change_scene(scene: PackedScene, free = true) -> void:
	change_scene_node(scene.instantiate(), free)
	
func get_current_scene() -> Node:
	return main.get_node("CurrentScene").get_child(0)
	
##endregion
	
##region Fading

enum {
	FADE_BLACK,
	FADE_WHITE,
}

func fade_out(color := FADE_BLACK) -> void:
	main.fade_out(color)
	
func fade_in(color := FADE_BLACK) -> void:
	main.fade_in(color)
	
func hide_fade() -> void:
	main.hide_fade()
	
##endregion

##region Music

func play_music(stream: AudioStream) -> void:
	if music.playing:
		music.stop()
	
	music.stream = stream
	music.volume_db = 0
	music.play()
	
func stop_music() -> void:
	music.stop()
	
func music_fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(music, "volume_db", -80, 0.5)
	await tween.finished
	music.stop()
	
func music_fade_in() -> void:
	var tween = create_tween()
	music.volume_db = -80
	tween.tween_property(music, "volume_db", 0, 0.5)
	
##endregion
