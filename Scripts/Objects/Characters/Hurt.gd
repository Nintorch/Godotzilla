extends "res://Scripts/Objects/Characters/PlayerState.gd"

@onready var timer := Timer.new()
var hurt_time := 0.0
var move_state: Node

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
	player.velocity.x = -player.direction * player.move_speed
	player.play_sfx("Hurt")
	timer.start(hurt_time)

func _on_timeout() -> void:
	# Might be called after the character died
	if player.state.current != PlayerCharacter.State.HURT:
		return
	player.animation_player.play("RESET")
	move_state.reset()
	player.state.current = player.move_state
