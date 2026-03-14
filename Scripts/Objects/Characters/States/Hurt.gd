extends "res://Scripts/Objects/Characters/States/PlayerState.gd"

@onready var timer := Timer.new()
var hurt_time := 0.0
var move_state: Node
var hurt_speed := 0.0

func state_init() -> void:
	move_state = player.state.states_list[player.move_state]
	timer.timeout.connect(_on_timeout)
	timer.one_shot = true
	add_child(timer)

func state_entered() -> void:
	if player.is_flying():
		player.velocity = Vector2()
	
	if player.animation_player.has_animation("Hurt"):
		player.animation_player.play("RESET")
		await get_tree().process_frame
		player.animation_player.play("Hurt")
	
	# -1 if facing right and 1 if facing left
	player.velocity.x = -player.direction * hurt_speed
	player.play_sfx("Hurt")
	timer.start(hurt_time)

func _on_timeout() -> void:
	# Might be called after the character died
	if player.state.current != PlayerCharacter.State.HURT:
		return
	player.animation_player.play("RESET")
	move_state.reset()
	player.state.current = player.move_state

func setup_from_attack(attack: AttackDescription) -> void:
	if not is_instance_valid(attack) or attack.hurt_speed < 0.0:
		hurt_speed = player.move_speed
	else:
		hurt_speed = attack.hurt_speed * 60
