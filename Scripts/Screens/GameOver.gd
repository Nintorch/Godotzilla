extends Node2D

@export var music: AudioStream
var finished := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.play_music(music)
	Global.fade_in()
	
	Global.music.finished.connect(finish)
	
	# The board hasn't been freed yet
	if is_instance_valid(Global.board):
		Global.board.queue_free()
		Global.board = null
	
func _process(_delta: float) -> void:
	if Global.any_action_button_pressed():
		finish()
	
func finish() -> void:
	if not finished:
		finished = true
		
		set_process(false)
		await Global.fade_out()
		Global.hide_fade()
		
		Global.change_scene(Global.main.initial_scene)
