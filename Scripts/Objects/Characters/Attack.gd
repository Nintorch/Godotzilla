extends "res://Scripts/Objects/Characters/State.gd"

@onready var walk_state = get_node("../Walk")
var current_attack = GameCharacter.Attack
var variation = 0

func state_init() -> void:
	parent.animation_player.connect("animation_finished", _on_animation_finished)

func _process(delta: float) -> void:
	walk_state.walk(delta)

func use(type: GameCharacter.Attack) -> void:
	parent.set_state(GameCharacter.State.ATTACK)
	parent.animation_player.play("RESET")
	await get_tree().process_frame
	
	match type:
		GameCharacter.Attack.PUNCH:
			variation = !variation
			if variation:
				parent.animation_player.play("Punch1")
			else:
				parent.animation_player.play("Punch2")
			parent.get_sfx("GodzillaPunch").play()

		GameCharacter.Attack.KICK:
			variation = !variation
			if variation:
				parent.animation_player.play("Kick1")
			else:
				parent.animation_player.play("Kick2")
			parent.get_sfx("GodzillaPunch").play()

func _on_animation_finished(anim_name: String) -> void:
	match anim_name:
		"Punch1", "Punch2":
			parent.animation_player.play("RESET")
			parent.set_state(GameCharacter.State.WALK)
		"Kick1", "Kick2":
			walk_state.walk_frame = 0
			parent.animation_player.play("RESET")
			parent.set_state(GameCharacter.State.WALK)
