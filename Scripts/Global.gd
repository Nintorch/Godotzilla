extends Node

const INPUT_PATH = "user://input.cfg"

var main: Node2D
var fading := false # set in Main.gd

var music: AudioStreamPlayer
var player: GameCharacter
var playing_levels: Array[PackedScene] = []
var board

signal widescreen_changed
signal fade_end
signal scene_changed(from: Node, to: Node)

const ACTIONS = [
	"Up", "Down", "Left", "Right",
	"B", "A", "Select", "Start"
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_input_mapping()
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ResetControls"):
		InputMap.load_from_project_settings()
		DirAccess.remove_absolute(INPUT_PATH)
		
	if Input.is_action_just_pressed("FullScreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

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
	
func get_content_size() -> Vector2i:
	return get_tree().get_root().content_scale_size
	
func get_next_level() -> PackedScene:
	if playing_levels.size() == 0:
		return null
	return playing_levels.pop_front()
	
func load_input_mapping() -> void:
	var file = ConfigFile.new()
	if file.load("user://input.cfg") != OK:
		return
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, file.get_value("Input", action))

func any_action_button_pressed() -> bool:
	for action in ["B", "A", "Select", "Start"]:
		if Input.is_action_just_pressed(action):
			return true
	return false

func get_boards() -> Array[BoardDescription]:
	return main.boards
	
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
