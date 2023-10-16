extends "res://Scripts/Objects/Characters/State.gd"

const YLIMIT = 120
var floor_checking: Area2D

func state_init() -> void:
	floor_checking = parent.get_node("MothraFloorChecking")

func _physics_process(delta: float) -> void:
	var xspeed = 2 * 60
	if Global.get_current_scene().is_camera_moving():
		xspeed = 1 * 60
	
	parent.velocity.x = roundi(parent.inputs[parent.Inputs.XINPUT]) * xspeed
	parent.velocity.y = roundi(parent.inputs[parent.Inputs.YINPUT]) * parent.move_speed
	
	floor_checking.position.y = parent.velocity.y * delta
	
	if floor_checking.has_overlapping_bodies() and parent.velocity.y > 0:
		parent.velocity.y = 0
	elif (parent.position.y + parent.velocity.y * delta) < YLIMIT \
		and parent.velocity.y < 0:
		parent.velocity.y = 0
		parent.position.y = YLIMIT

func reset() -> void:
	parent.animation_player.play("Idle")
