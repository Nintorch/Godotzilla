extends Node

const SCORE_MAX := 9999999

var main: Node2D

var _fade_player: AnimationPlayer
var _fader: ColorRect

var music: AudioStreamPlayer
var player: PlayerCharacter
var playing_levels: Array[PackedScene] = []
var board: Board
var score := 0
var level_data: Level.GameplayData = null

signal widescreen_changed
signal fullscreen_changed(flag: bool) # only through use_fullscreen()
signal scene_changed(from: Node, to: Node)
signal score_changed(new_value: int)
signal fade_end

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(_delta: float) -> void:
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
	const FULLSCREEN = DisplayServer.WINDOW_MODE_FULLSCREEN
	if flag and not is_fullscreen():
		DisplayServer.window_set_mode(FULLSCREEN)
		fullscreen_changed.emit(true)
	elif not flag and is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_changed.emit(false)
		
func is_fullscreen() -> bool:
	const FULLSCREEN = DisplayServer.WINDOW_MODE_FULLSCREEN
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
	
func add_score(value: int, delta: int = 20) -> void:
	if value < 0:
		return
	if delta <= 0:
		delta = 20
	
	# Gradually add score for the player.
	# I don't make a target score here and instead use score_given
	# because the player might get some more score while the previous score
	# hasn't been given out fully, so they both have to increase the resulting
	# score
	var score_given := 0
	while score_given < value:
		score += delta
		score_given += delta
		if score_given > value:
			score -= score_given - value
		score = mini(score, SCORE_MAX)
		score_changed.emit(score)
		await get_tree().create_timer(0.1, false).timeout
	
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
	
func get_current_scene() -> Node:
	return main.get_node("CurrentScene").get_child(0)
	
#endregion
	
#region Fading

enum FadeColor {
	BLACK,
	WHITE,
}

func is_fading() -> bool:
	return _fade_player.is_playing()
	
func is_fade_shown() -> bool:
	return is_fading() or _fader.modulate.a > 0

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
	
func play_sfx_globally(stream: AudioStream) -> void:
	var node := AudioStreamPlayer.new()
	node.stream = stream
	node.bus = "SFX"
	node.finished.connect(node.queue_free)
	add_child(node)
	node.play()
	
func is_sfx_playing_globally(stream: AudioStream) -> bool:
	return Global.get_children().filter(func(x: Node) -> bool:
		return (x is AudioStreamPlayer and (x as AudioStreamPlayer).stream == stream)
		).size() != 0
	
#endregion
