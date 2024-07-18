extends Node2D

@export var initial_scene: PackedScene = preload("res://Scenes/TitleScreen.tscn")
@export var wait_before_start := false # Mostly just a debugging feature
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	Global.main = self
	Global.music = $Music
	Global._fade_player = $CanvasLayer/FadePlayer
	Global._fader = $CanvasLayer/Fader
	
	if wait_before_start:
		get_tree().paused = true
		get_tree().process_frame.connect(func():
			if Global.any_action_button_pressed():
				get_tree().paused = false
				start()
				)
	else:
		start()
	
func start() -> void:
	$CurrentScene.add_child(initial_scene.instantiate())
	Global.widescreen_changed.connect(_on_widescreen_change)
	Global.scene_changed.connect(func(_from: Node, _to: Node) -> void:
		_on_widescreen_change()
		)
	
	Global.hide_fade()
	_on_widescreen_change()

func _on_widescreen_change() -> void:
	$CanvasLayer/Fader.size = Global.get_content_size()
	
	if not Global.get_current_scene() is Node2D:
		return
	
	var curscene: Node2D = Global.get_current_scene() as Node2D
	if not get_viewport().get_camera_2d():
		curscene.position.x = (Global.get_content_size().x - \
			Global.get_default_resolution().x) / 2
		return
		
	if get_viewport().get_camera_2d().limit_right <= Global.get_content_size().x:
		curscene.position.x = (get_viewport().get_camera_2d().limit_right - \
			Global.get_content_size().x) / 2
	else:
		curscene.position.x = 0
