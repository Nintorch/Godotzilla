extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.play_music(preload("res://Audio/Soundtrack/GameOver.ogg"))
	Global.fade_in()
	
	Global.music.finished.connect(finish)
	
func finish() -> void:
	Global.fade_out()
	await Global.fade_end
	Global.change_scene(Global.main.initial_scene)
