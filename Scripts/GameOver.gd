extends Node2D

var finished := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.play_music(preload("res://Audio/Soundtrack/GameOver.ogg"))
	Global.fade_in()
	
	Global.music.finished.connect(finish)
	# The board hasn't been freed yet
	Global.board.queue_free()
	
func _process(_delta: float) -> void:
	if Global.any_action_button_pressed():
		finish()
	
func finish() -> void:
	if not finished:
		finished = true
		set_process(false)
		Global.fade_out()
		await Global.fade_end
		Global.change_scene(Global.main.initial_scene)
