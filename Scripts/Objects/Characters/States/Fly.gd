extends "res://Scripts/Objects/Characters/States/PlayerState.gd"

var floor_checking: Area2D

func state_init() -> void:
	floor_checking = player.get_node("MothraFloorChecking")

func _physics_process(delta: float) -> void:
	move(delta)
		
func _process(_delta: float) -> void:
	player.skin.fly_process()

func move(delta: float) -> void:
	var xspeed: float = player.move_speed
	var ylimit := player.skin.flying_top_y_limit
	
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		ylimit += camera.limit_top
		if camera.is_camera_moving():
			xspeed = player.skin.flying_move_speed_2 * 60
		
	player.velocity.x = signf(player.inputs[player.Inputs.XINPUT]) * xspeed
	player.velocity.y = signf(player.inputs[player.Inputs.YINPUT]) * player.move_speed
	
	if player.allow_direction_changing and signf(player.inputs[player.Inputs.XINPUT]) != 0:
		player.direction = signf(player.inputs[player.Inputs.XINPUT])
	
	floor_checking.position.y = \
		player.skin.flying_floor_check_y_offset + player.velocity.y * delta
	
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
