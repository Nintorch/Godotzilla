extends Node2D

@export var initial_scene: PackedScene = preload("res://Scenes/TitleScreen.tscn")
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	Global.main = self
	Global.music = $Music
	$CurrentScene.add_child(initial_scene.instantiate())
	
	Global.widescreen_changed.connect(_on_widescreen_change)
	Global.scene_changed.connect(func(_from: Node, _to: Node) -> void:
		_on_widescreen_change()
		)
	
	hide_fade()
	_on_widescreen_change()
	
func set_fade_color(color := Global.FADE_BLACK) -> void:
	match color:
		Global.FADE_BLACK:
			$CanvasLayer/Fader.color = Color.BLACK
		Global.FADE_WHITE:
			$CanvasLayer/Fader.color = Color.WHITE

func fade_out(color := Global.FADE_BLACK) -> void:
	Global.fading = true
	set_fade_color(color)
	$CanvasLayer/FadePlayer.play_backwards("FadeIn")
	
func fade_in(color := Global.FADE_BLACK) -> void:
	Global.fading = true
	set_fade_color(color)
	$CanvasLayer/FadePlayer.play("FadeIn")
	
func hide_fade() -> void:
	$CanvasLayer/Fader.modulate.a = 0

func _on_animation_finished(_anim_name: StringName) -> void:
	Global.fading = false
	Global.fade_end.emit()

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
