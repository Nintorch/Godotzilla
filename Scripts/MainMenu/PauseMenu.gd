extends "res://Scripts/MainMenu/BaseMenu.gd"

var return_scene: Node2D

func _ready() -> void:
	super._ready()
	Global.music.stream_paused = true
	Global.get_global_sfx("Pause").play()
