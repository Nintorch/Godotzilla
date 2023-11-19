extends "res://Scripts/Objects/Characters/State.gd"

const YLIMIT = 120
var floor_checking: Area2D
var attack_timer := Timer.new()

func state_init() -> void:
	floor_checking = parent.get_node("MothraFloorChecking")
	attack_timer.one_shot = true
	add_child(attack_timer)

func _physics_process(delta: float) -> void:
	move(delta)
		
func _process(delta):
	if (parent.inputs_pressed[parent.Inputs.A]
		or parent.inputs_pressed[parent.Inputs.B]) \
		and attack_timer.is_stopped():
			parent.use_attack(GameCharacter.Attack.EYE_BEAM)
			attack_timer.start(0.2)
	
	if parent.inputs_pressed[parent.Inputs.START]:
		parent.use_attack(GameCharacter.Attack.WING_ATTACK)

func move(delta) -> void:
	var xspeed = 2 * 60
	if Global.get_current_scene().is_camera_moving():
		xspeed = 1 * 60
	
	parent.velocity.x = parent.inputs[parent.Inputs.XINPUT] * xspeed
	parent.velocity.y = parent.inputs[parent.Inputs.YINPUT] * parent.move_speed
	
	floor_checking.position.y = parent.velocity.y * delta
	
	if floor_checking.has_overlapping_bodies() and parent.velocity.y > 0:
		parent.velocity.y = 0
	elif (parent.position.y + parent.velocity.y * delta) < YLIMIT \
		and parent.velocity.y < 0:
		parent.velocity.y = 0
		parent.position.y = YLIMIT

func reset() -> void:
	parent.animation_player.play("Idle")
