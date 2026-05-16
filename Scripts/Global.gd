extends Node

const EXPLOSION = preload("uid://cpxp6boj611rb")

const SCORE_MAX := 9999999

## Reference to the main scene, i.e. container of all scenes
var main: Node2D

var _fade_player: AnimationPlayer
var _fader: ShaderMaterial
var _fade_rect: ColorRect

## AudioStreamPlayer node dedicated to playing music in the game
var music: AudioStreamPlayer
## Current player
var player: PlayerCharacter
## Array of levels that the player will have to go through after the current one
var playing_levels: Array[PackedScene] = []
## Current planet board
var board: Board
## Amount of score the player currently has
var score := 0
## Important gameplay that should be passed between levels 
var level_data: Level.GameplayData
var hud: HUD

var controller_vibration := true

var _initial_scene := true

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

## Returns the default game resolution on 1x scaling
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
	const FULLSCREEN := DisplayServer.WINDOW_MODE_FULLSCREEN
	if flag and not is_fullscreen():
		DisplayServer.window_set_mode(FULLSCREEN)
		fullscreen_changed.emit(true)
	elif not flag and is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_changed.emit(false)
		
func is_fullscreen() -> bool:
	const FULLSCREEN := DisplayServer.WINDOW_MODE_FULLSCREEN
	return DisplayServer.window_get_mode() == FULLSCREEN
	
## Content size is basically the size of the pixel game window
func get_content_size() -> Vector2i:
	return get_tree().get_root().content_scale_size
	
#endregion

func get_left_camera_boundary() -> float:
	return (get_viewport().get_camera_2d().get_screen_center_position().x
		- get_content_size().x / 2)

func get_right_camera_boundary() -> float:
	return (get_viewport().get_camera_2d().get_screen_center_position().x
		+ get_content_size().x / 2)

func get_top_camera_boundary() -> float:
	return (get_viewport().get_camera_2d().get_screen_center_position().y
		- get_content_size().y / 2)

func get_bottom_camera_boundary() -> float:
	return (get_viewport().get_camera_2d().get_screen_center_position().y
		+ get_content_size().y / 2)
	
## Get the next level the player should play (if any) and remove it from the queue
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

## Changes the current scene to the specified Node reference
func change_scene_node(node: Node, free := true) -> void:
	var curscene_parent: Node = main.get_scene_container()
	var curscene := curscene_parent.get_child(0)
	
	if curscene == node:
		return
		
	_initial_scene = false
	
	curscene_parent.remove_child(curscene)
	if free:
		curscene.queue_free()
	curscene_parent.add_child(node)
	
	scene_changed.emit(curscene, node)
	
## Changes the current scene to the specified scene
func change_scene(scene: PackedScene, free := true) -> void:
	change_scene_node(scene.instantiate(), free)
	
## Get the scene that the player entered upon starting the game
func get_initial_scene() -> PackedScene:
	return main.initial_scene
	
func is_initial_scene() -> bool:
	return _initial_scene
	
## The currently playing scene
func get_current_scene() -> Node:
	if main == null:
		push_error("You started the game incorrectly. You should use the 'Run Project' button, not the 'Run Current Scene'. Expect errors when the game runs.")
	return main.get_scene_container().get_child(0)
	
#endregion
	
#region Fading

enum FadeColor {
	BLACK,
	WHITE,
}

func is_fading() -> bool:
	return _fade_player.is_playing()
	
func is_fade_shown() -> bool:
	return _fader.get_shader_parameter("Progress") > 0

func _perform_fade(use_fade_in: bool, pause_game: bool, color: FadeColor, custom_speed := 1.0) -> void:
	if pause_game:
		get_tree().paused = true
	
	_fade_rect.show()
	_fader.set_shader_parameter("WhiteFade", color == FadeColor.WHITE)
	if use_fade_in:
		_fade_player.play("FadeIn", -1, custom_speed)
	else:
		_fade_player.play("FadeIn", -1, -custom_speed, true)
	await _fade_player.animation_finished
	if use_fade_in:
		_fade_rect.hide()
	fade_end.emit()
	
	if pause_game:
		get_tree().paused = false

## Show the fade out effect on the screen
func fade_out(color := FadeColor.BLACK, custom_speed := 1.0) -> void:
	await _perform_fade(false, false, color, custom_speed)
	
## Show the fade in effect on the screen
func fade_in(color := FadeColor.BLACK, custom_speed := 1.0) -> void:
	await _perform_fade(true, false, color, custom_speed)
	
## Show the fade out effect on the screen while also pausing the game while it's playing
func fade_out_paused(color := FadeColor.BLACK, custom_speed := 1.0) -> void:
	await _perform_fade(false, true, color, custom_speed)
	
## Show the fade in effect on the screen while also pausing the game while it's playing
func fade_in_paused(color := FadeColor.BLACK, custom_speed := 1.0) -> void:
	await _perform_fade(true, true, color, custom_speed)
	
## Make the game screen visible instantly from fade effect
func hide_fade() -> void:
	_fader.set_shader_parameter("Progress", 0.0)
	
## Make the game screen black instantly via fade effect
func show_fade() -> void:
	_fader.set_shader_parameter("Progress", 1.0)
	
#endregion

#region Music

func play_music(stream: AudioStream, from_position: float = 0.0) -> void:
	if music.playing:
		music.stop()
	
	music.stream = stream
	music.volume_db = 0
	music.play(from_position)
	
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
	
func play_global_sfx(sfx_name: String) -> AudioStreamPlayer:
	var sfx: AudioStreamPlayer = main.get_node("GlobalSFX/" + sfx_name)
	sfx.play()
	return sfx

#endregion


func create_explosion(explosion_global_position: Vector2, sfx := true) -> void:
	var explosion: Node2D = EXPLOSION.instantiate()
	get_current_scene().add_child(explosion)
	explosion.global_position = explosion_global_position
	if sfx:
		play_global_sfx("Explosion")