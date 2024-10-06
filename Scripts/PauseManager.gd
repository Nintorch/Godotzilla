extends Node

const PAUSE_MENU := preload("res://Scenes/MainMenu/PauseMenu.tscn")

var previous_scene: Node

signal pause_finished

func accept_pause() -> void:
	if not Global.is_fading() and Input.is_action_just_pressed("Select"):
		start_pause()
		
func start_pause() -> void:
	previous_scene = Global.get_current_scene()
	# Change to pause menu scene but don't free the previous one
	Global.change_scene(PAUSE_MENU, false)
	# Position the current pause menu on the center of the screen
	Global.get_current_scene().position.x = \
		(Global.get_content_size().x - Global.get_default_resolution().x) / 2
	get_tree().paused = true
	
	Global.music.stream_paused = true
	Global.play_global_sfx("Pause")

func finish_pause() -> void:
	var current_pause_menu := Global.get_current_scene()
	# Don't free the pause menu yet, we will free it later below
	Global.change_scene_node(previous_scene, false)
	previous_scene = null
	get_tree().paused = false
	
	pause_finished.emit()
	
	await Global.play_global_sfx("Pause").finished
	
	# Don't resume the music if the player was fast enough
	# to pause again before sfx.finished above fired and
	# they're on pause menu again
	if previous_scene == null:
		Global.music.stream_paused = false
	
	current_pause_menu.queue_free()

func prepare_for_exit() -> void:
	if is_instance_valid(Global.board):
		Global.board.queue_free()
	if is_instance_valid(previous_scene):
		previous_scene.queue_free()
