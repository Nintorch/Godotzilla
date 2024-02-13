extends "res://Scripts/MainMenu/BaseMenu.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	Global.hide_fade()
	Global.play_music(preload("res://Audio/Soundtrack/MainMenu.ogg"))
