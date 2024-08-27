extends State

@onready var timer := Timer.new()
var hurt_time := 0.0
var move_state: Node

func state_init() -> void:
	move_state = parent.state.states_list[parent.move_state]
	timer.timeout.connect(_on_timeout)
	timer.one_shot = true
	add_child(timer)

func state_entered() -> void:
	if parent.is_flying():
		parent.velocity = Vector2()
	
	parent.animation_player.play("RESET")
	await get_tree().process_frame
	if parent.animation_player.has_animation("Hurt"):
		parent.animation_player.play("Hurt")
	
	# -1 if facing right and 1 if facing left
	parent.velocity.x = -parent.direction * parent.move_speed
	parent.get_sfx("Hurt").play()
	timer.start(hurt_time)

func _on_timeout() -> void:
	# Might be called after the character died
	if parent.state.current != PlayerCharacter.State.HURT:
		return
	parent.animation_player.play("RESET")
	move_state.reset()
	parent.state.current = parent.move_state
