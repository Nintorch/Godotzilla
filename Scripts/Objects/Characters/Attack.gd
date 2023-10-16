extends "res://Scripts/Objects/Characters/State.gd"

var move_state: Node
var current_attack = GameCharacter.Attack
var variation = 0

func state_init() -> void:
	move_state = parent.states_list[parent.move_state]
	parent.animation_player.connect("animation_finished", _on_animation_finished)

func _process(delta: float) -> void:
	move_state.move(delta)

func use(type: GameCharacter.Attack) -> void:
	parent.set_state(GameCharacter.State.ATTACK)
	
	match type:
		GameCharacter.Attack.PUNCH, GameCharacter.Attack.KICK:
			parent.animation_player.play("RESET")
			await get_tree().process_frame
	
	match type:
		GameCharacter.Attack.PUNCH:
			variation = !variation
			if variation:
				parent.animation_player.play("Punch1")
			else:
				parent.animation_player.play("Punch2")
			parent.get_sfx("Punch").play()

		GameCharacter.Attack.KICK:
			variation = !variation
			if variation:
				parent.animation_player.play("Kick1")
			else:
				parent.animation_player.play("Kick2")
			parent.get_sfx("Punch").play()
			
		GameCharacter.Attack.TAIL_WHIP:
			parent.animation_player.play("TailWhip")

func _on_animation_finished(anim_name: String) -> void:
	match anim_name:
		"Punch1", "Punch2":
			parent.animation_player.play("RESET")
			parent.set_state(GameCharacter.State.WALK)
		"Kick1", "Kick2":
			move_state.walk_frame = 0
			parent.animation_player.play("RESET")
			parent.set_state(GameCharacter.State.WALK)
		"TailWhip":
			move_state.walk_frame = 0
			if parent.inputs[GameCharacter.Inputs.YINPUT] > 0:
				parent.animation_player.play("Crouch")
			else:
				parent.animation_player.play("RESET")
			parent.set_state(GameCharacter.State.WALK)
