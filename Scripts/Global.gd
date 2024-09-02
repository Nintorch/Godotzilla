extends Node

const SETTINGS_PATH = "user://settings.cfg"
const SAVE_FILE_PATH = "user://save.cfg"
const SAVE_FILE_PASS = "Godotzilla" # Change this in your game!!!

var main: Node2D

var _fade_player: AnimationPlayer
var _fader: ColorRect

var music: AudioStreamPlayer
var player: PlayerCharacter
var playing_levels: Array[PackedScene] = []
var board: Board
var score := 0

var save_slot_id := -1 # -1 means no save
var save_data := {
	board_id = "",
	board_data = {},
	score = 0,
}

signal widescreen_changed
signal fullscreen_changed(flag: bool) # only through use_fullscreen()
signal scene_changed(from: Node, to: Node)
signal score_changed(new_value: int)
signal fade_end
signal pause_finished

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_settings()
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ResetControls"):
		InputMap.load_from_project_settings()
		var file := load_settings_file()
		file.erase_section("Input")
		save_settings_file(file)
		
	if Input.is_action_just_pressed("FullScreen"):
		use_fullscreen(not is_fullscreen())
		
#region Game window related

func get_default_resolution() -> Vector2i:
	return Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
		)

func use_widescreen(flag: bool) -> void:
	var size := get_default_resolution()
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
	
#endregion
	
func get_next_level() -> PackedScene:
	if playing_levels.size() == 0:
		return null
	return playing_levels.pop_front()

func any_action_button_pressed() -> bool:
	for action: String in ["B", "A", "Select", "Start"]:
		if Input.is_action_just_pressed(action):
			return true
	return false
	
var pause_visible_objects: Array[Node] = []
	
func accept_pause() -> void:
	if not Global.is_fading() and Input.is_action_just_pressed("Select"):
		var pause := preload("res://Scenes/MainMenu/PauseMenu.tscn").instantiate()
		pause.return_scene = get_current_scene()
		
		get_current_scene().hide()
		pause_visible_objects = get_all_visible_children(get_current_scene())
		pause_visible_objects.map(func(x: Node) -> void: x.visible = false)
		
		var prev_pause: Node = main.canvas_layer.get_node_or_null(String(pause.name))
		if prev_pause != null:
			main.canvas_layer.remove_child(prev_pause)
			
		main.canvas_layer.add_child(pause)
		main.canvas_layer.move_child(pause, 0)
		pause.position.x = (get_content_size().x - get_default_resolution().x) / 2
		get_tree().paused = true

func finish_pause() -> void:
	pause_finished.emit()
		
func get_all_visible_children(node: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for N in node.get_children():
		if "visible" not in N or not N.visible:
			continue
		nodes.append(N)
		if N.get_child_count() > 0:
			nodes.append_array(get_all_visible_children(N))
	return nodes
	
func add_score(value: int) -> void:
	if value > 0:
		score += value
		score_changed.emit(score)

#region Save files

func load_game_settings() -> void:
	var file := load_settings_file()
	
	VideoSettings.load_video_settings(file)
	SoundSettings.load_sound_settings(file)
	ControlsSettings.init_controls()
	ControlsSettings.load_mapping(file)

func load_settings_file() -> ConfigFile:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		save_settings_file(file)
	return file
	
func save_settings_file(file: ConfigFile) -> void:
	file.save(SETTINGS_PATH)
	
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
	
#region Scene changing

func change_scene_node(node: Node, free := true) -> void:
	var curscene_parent := main.get_node("CurrentScene")
	var curscene := curscene_parent.get_child(0)
	
	curscene_parent.remove_child(curscene)
	if free:
		curscene.queue_free()
	curscene_parent.add_child(node)
	
	scene_changed.emit(curscene, node)
	
func change_scene(scene: PackedScene, free := true) -> void:
	change_scene_node(scene.instantiate(), free)
	
func get_initial_scene() -> PackedScene:
	return main.initial_scene
	
func get_current_scene() -> Node2D:
	return main.get_node("CurrentScene").get_child(0)
	
#endregion
	
#region Fading

enum FadeColor {
	BLACK,
	WHITE,
}

func is_fading() -> bool:
	return _fade_player.is_playing()

func _perform_fade(callable: Callable, pause_game: bool, color: FadeColor) -> void:
	if pause_game:
		get_tree().paused = true
		
	_fader.color = [Color.BLACK, Color.WHITE][color]
	callable.call()
	await _fade_player.animation_finished
	fade_end.emit()
	
	if pause_game:
		get_tree().paused = false

func fade_out(color := FadeColor.BLACK) -> void:
	await _perform_fade(func() -> void: _fade_player.play_backwards("FadeIn"), false, color)
	
func fade_in(color := FadeColor.BLACK) -> void:
	await _perform_fade(func() -> void: _fade_player.play("FadeIn"), false, color)
	
func fade_out_paused(color := FadeColor.BLACK) -> void:
	await _perform_fade(func() -> void: _fade_player.play_backwards("FadeIn"), true, color)
	
func fade_in_paused(color := FadeColor.BLACK) -> void:
	await _perform_fade(func() -> void: _fade_player.play("FadeIn"), true, color)
	
func hide_fade() -> void:
	_fader.modulate.a = 0
	
func show_fade() -> void:
	_fader.modulate.a = 1
	
#endregion

#region Music

func play_music(stream: AudioStream) -> void:
	if music.playing:
		music.stop()
	
	music.stream = stream
	music.volume_db = 0
	music.play()
	
func stop_music() -> void:
	music.stop()
	
func music_fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -80, 0.5)
	await tween.finished
	music.stop()
	
func music_fade_in() -> void:
	var tween := create_tween()
	music.volume_db = -80
	tween.tween_property(music, "volume_db", 0, 0.5)
	
func get_global_sfx(sfx_name: String) -> AudioStreamPlayer:
	return main.get_node("GlobalSFX/" + sfx_name)
	
#endregion
