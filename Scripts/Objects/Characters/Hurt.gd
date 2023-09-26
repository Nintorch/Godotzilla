extends "res://Scripts/Objects/Characters/State.gd"

@onready var move_state = $"../Move"

func state_init() -> void:
	parent.animation_player.connect("animation_finished", _on_animation_finished)

func state_entered() -> void:
	parent.animation_player.play("RESET")
	await get_tree().process_frame
	parent.animation_player.play("Hurt")
	
	# -1 if facing right and 1 if facing left
	parent.velocity.x = -parent.scale.x * 60
	parent.get_sfx("Hurt").play()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Hurt":
		move_state.walk_frame = 0
		parent.animation_player.play("RESET")
		parent.set_state(GameCharacter.State.MOVE)
