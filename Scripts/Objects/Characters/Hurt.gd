extends "res://Scripts/Objects/Characters/State.gd"

@onready var timer := Timer.new()
var hurt_time := 0.0
var move_state: Node

func state_init() -> void:
	move_state = parent.states_list[parent.move_state]
	timer.timeout.connect(_on_timeout)
	timer.one_shot = true
	add_child(timer)

func state_entered() -> void:
	parent.animation_player.play("RESET")
	await get_tree().process_frame
	parent.animation_player.play("Hurt")
	
	# -1 if facing right and 1 if facing left
	parent.velocity.x = -parent.direction * parent.move_speed
	parent.get_sfx("Hurt").play()
	timer.start(hurt_time)

func _on_timeout() -> void:
	# Might be called after the character died
	if parent.state != GameCharacter.State.HURT:
		return
	parent.animation_player.play("RESET")
	move_state.reset()
	parent.state = parent.move_state
