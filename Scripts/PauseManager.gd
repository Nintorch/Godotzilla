extends Node

const PAUSE_MENU := preload("res://Scenes/Screens/MainMenu/PauseMenu.tscn")

var previous_scene: Node2D
var pause_node: Node2D

signal pause_started
signal pause_finished

func accept_pause() -> void:
	if not Global.is_fading() and Input.is_action_just_pressed("Select"):
		start_pause()
		
func start_pause() -> void:
	# Create the pause menu alongside the current scene to avoid having bugs
	# due to nodes not being in the scene tree
	previous_scene = Global.get_current_scene()
	pause_node = PAUSE_MENU.instantiate()
	previous_scene.add_sibling(pause_node)
	previous_scene.hide()
	# Position the current pause menu on the center of the screen
	pause_node.position.x = \
		(Global.get_content_size().x - Global.get_default_resolution().x) / 2 + Global.get_left_camera_boundary()
	pause_node.position.y = Global.get_top_camera_boundary()
	get_tree().paused = true
	
	Global.music.stream_paused = true
	Global.play_global_sfx("Pause")
	
	pause_started.emit()

func finish_pause() -> void:
	# Don't free the pause menu yet, we will free it later below
	pause_node.queue_free()
	previous_scene.show()
	get_tree().paused = false
	
	pause_finished.emit()
	
	await Global.play_global_sfx("Pause").finished
	
	# Don't resume the music if the player was fast enough
	# to pause again before sfx.finished above fired and
	# they're on pause menu again
	if not is_instance_valid(pause_node) or not pause_node.visible:
		Global.music.stream_paused = false

func prepare_for_exit() -> void:
	if is_instance_valid(Global.board):
		Global.board.queue_free()
