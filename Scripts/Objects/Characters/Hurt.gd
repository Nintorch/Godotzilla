extends "res://Scripts/Objects/Characters/State.gd"

@onready var move_state = $"../Move"
@onready var timer = Timer.new()
var hurt_time := 0.0

func state_init() -> void:
	timer.timeout.connect(_on_timeout)
	timer.one_shot = true
	add_child(timer)

func state_entered() -> void:
	parent.animation_player.play("RESET")
	await get_tree().process_frame
	parent.animation_player.play("Hurt")
	
	# -1 if facing right and 1 if facing left
	parent.velocity.x = -parent.scale.x * 60
	parent.get_sfx("Hurt").play()
	timer.start(hurt_time)

func _on_timeout() -> void:
	# Might be called after the character died
	if parent.state != GameCharacter.State.HURT:
		return
	move_state.walk_frame = 0
	parent.animation_player.play("RESET")
	parent.set_state(GameCharacter.State.MOVE)
