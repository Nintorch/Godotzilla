extends Node2D

@export var initial_scene: PackedScene

func _ready() -> void:
	Global.main = self
	Global.music = $Music
	$CurrentScene.add_child(initial_scene.instantiate())
	
	$Fade/Fader.size = Global.get_content_size()
	$Fade/Fader.modulate.a = 0
	
	scene_changed()

func fade_out() -> void:
	$Fade/AnimationPlayer.play_backwards("FadeIn")
	
func fade_in() -> void:
	$Fade/AnimationPlayer.play("FadeIn")

func _on_animation_finished(_anim_name: StringName) -> void:
	Global.emit_signal("fade_end")
	
func scene_changed() -> void:
	if not get_viewport().get_camera_2d():
		return
	if get_viewport().get_camera_2d().limit_right <= Global.get_content_size().x:
		$CurrentScene.position.x = (get_viewport().get_camera_2d().limit_right - \
			Global.get_content_size().x) / 2
	else:
		$CurrentScene.position.x = 0
