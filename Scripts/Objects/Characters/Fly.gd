extends "res://Scripts/Objects/Characters/State.gd"

const YLIMIT = 72
var floor_checking: Area2D
var attack_timer := Timer.new()

func state_init() -> void:
	floor_checking = parent.get_node("MothraFloorChecking")
	attack_timer.one_shot = true
	add_child(attack_timer)

func _physics_process(delta: float) -> void:
	move(delta)
		
func _process(_delta: float):
	if (parent.inputs_pressed[parent.Inputs.A]
		or parent.inputs_pressed[parent.Inputs.B]) \
		and attack_timer.is_stopped():
			parent.use_attack(GameCharacter.Attack.EYE_BEAM)
			attack_timer.start(0.2)
	
	if parent.inputs_pressed[parent.Inputs.START]:
		parent.use_attack(GameCharacter.Attack.WING_ATTACK)

func move(delta: float) -> void:
	var xspeed = 2 * 60
	if get_viewport().get_camera_2d().is_camera_moving():
		xspeed = 1 * 60
		
	parent.velocity.x = signf(parent.inputs[parent.Inputs.XINPUT]) * xspeed
	parent.velocity.y = signf(parent.inputs[parent.Inputs.YINPUT]) * parent.move_speed
	
	if parent.allow_direction_changing and signf(parent.inputs[parent.Inputs.XINPUT]) != 0:
		parent.direction = signf(parent.inputs[parent.Inputs.XINPUT])
	
	floor_checking.position.y = parent.velocity.y * delta
	
	var ylimit := get_viewport().get_camera_2d().limit_top + YLIMIT
	if Global.get_current_scene().has_node("HUD"):
		ylimit += Global.get_current_scene().get_node("HUD").vertical_size
	
	if floor_checking.has_overlapping_bodies() and parent.velocity.y > 0:
		parent.velocity.y = 0
	elif (parent.position.y + parent.velocity.y * delta) < ylimit \
		and parent.velocity.y < 0:
		parent.velocity.y = 0
		parent.position.y = ylimit

func reset() -> void:
	parent.animation_player.play("Idle")
