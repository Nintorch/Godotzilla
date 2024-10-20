extends "res://Scripts/Objects/Characters/PlayerState.gd"

const YLIMIT = 72
var floor_checking: Area2D
var attack_timer := Timer.new()

func state_init() -> void:
	floor_checking = player.get_node("MothraFloorChecking")
	attack_timer.one_shot = true
	add_child(attack_timer)

func _physics_process(delta: float) -> void:
	move(delta)
		
func _process(_delta: float) -> void:
	if player.character == PlayerCharacter.Type.MOTHRA:
		if (player.inputs_pressed[player.Inputs.A]
			or player.inputs_pressed[player.Inputs.B]) \
			and attack_timer.is_stopped():
				player.use_attack(PlayerCharacter.Attack.EYE_BEAM)
				attack_timer.start(0.2)
		
		if player.inputs_pressed[player.Inputs.START]:
			player.use_attack(PlayerCharacter.Attack.WING_ATTACK)

func move(delta: float) -> void:
	var xspeed: float = player.move_speed
	var ylimit := YLIMIT
	
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		ylimit += camera.limit_top
		if camera.is_camera_moving():
			xspeed = 1 * 60
		
	player.velocity.x = signf(player.inputs[player.Inputs.XINPUT]) * xspeed
	player.velocity.y = signf(player.inputs[player.Inputs.YINPUT]) * player.move_speed
	
	if player.allow_direction_changing and signf(player.inputs[player.Inputs.XINPUT]) != 0:
		player.direction = signf(player.inputs[player.Inputs.XINPUT])
	
	floor_checking.position.y = player.velocity.y * delta
	
	if Global.get_current_scene().has_node("HUD"):
		ylimit += Global.get_current_scene().get_node("HUD").vertical_size
	
	if floor_checking.has_overlapping_bodies() and player.velocity.y > 0:
		player.velocity.y = 0
	elif (player.position.y + player.velocity.y * delta) < ylimit \
		and player.velocity.y < 0:
		player.velocity.y = 0
		player.position.y = ylimit

func reset() -> void:
	player.animation_player.play("Idle")
