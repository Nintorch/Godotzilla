extends Node2D

## The scene that runs when you run the game from the editor
@export var initial_scene_debug: PackedScene = preload("uid://bcqw43w8eilwf")
## The scene that runs when you run the exported game
@export var initial_scene_release: PackedScene = preload("uid://bcqw43w8eilwf")
@export var wait_before_start := false # Mostly just a debugging feature
@onready var fade: CanvasLayer = $Fade

var wait_before_start_flag := false
var initial_scene: PackedScene

func _ready() -> void:
	Global.main = self
	Global.music = $Music
	Global._fade_player = $Fade/FadePlayer
	Global._fader = $Fade/FadeRect.material as ShaderMaterial
	Global._fade_rect = $Fade/FadeRect
	
	if OS.is_debug_build():
		initial_scene = initial_scene_debug
		if wait_before_start:
			get_tree().paused = true
			get_tree().process_frame.connect(_wait_before_start_func)
		else:
			start()
	else:
		initial_scene = initial_scene_release
		
func _wait_before_start_func() -> void:
	if not wait_before_start_flag and Global.any_action_button_pressed():
		wait_before_start_flag = true
		get_tree().paused = false
		get_tree().process_frame.disconnect(_wait_before_start_func)
		start()
	
func start() -> void:
	Global.last_scene = initial_scene
	get_scene_container().add_child(initial_scene.instantiate())
	Global.widescreen_changed.connect(_on_widescreen_change)
	Global.scene_changed.connect(func(_from: Node, _to: Node) -> void:
		_on_widescreen_change()
		)
	
	Global.hide_fade()
	_on_widescreen_change()
	
func get_scene_container() -> Node:
	return %CurrentScene

func _on_widescreen_change() -> void:	
	var curscene: Node2D = Global.get_current_scene() as Node2D
	if curscene == null:
		return
	
	var camera := curscene.get_viewport().get_camera_2d()
	if camera == null:
		curscene.position.x = (Global.get_content_size().x - \
			Global.get_default_resolution().x) / 2
		return

	if camera.limit_right <= Global.get_content_size().x:
		curscene.position.x = (camera.limit_right - Global.get_content_size().x) / 2
	else:
		curscene.position.x = 0
