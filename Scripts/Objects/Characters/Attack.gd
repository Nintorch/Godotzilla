extends "res://Scripts/Objects/Characters/State.gd"

var move_state: Node
var current_attack = GameCharacter.Attack
var variation = 0

const MothraParticle := preload("res://Objects/Characters/MothraParticle.tscn")

func state_init() -> void:
	move_state = parent.states_list[parent.move_state]
	parent.animation_player.connect("animation_finished", _on_animation_finished)

func _process(delta: float) -> void:
	move_state.move(delta)

func use(type: GameCharacter.Attack) -> void:
	parent.state = GameCharacter.State.ATTACK
	
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
			
		GameCharacter.Attack.EYE_BEAM:
			var particle = MothraParticle.instantiate()
			Global.get_current_scene().add_child(particle)
			particle.player = parent
			particle.setup(particle.Type.EYE_BEAM)
			particle.global_position = \
				parent.global_position + Vector2(20 * parent.scale.x, 0)
			parent.state = parent.move_state
			
		GameCharacter.Attack.WING_ATTACK:
			for i in 6:
				var particle = MothraParticle.instantiate()
				Global.get_current_scene().add_child(particle)
				particle.player = parent
				particle.setup(particle.Type.WING)
				particle.global_position = parent.global_position
				parent.state = parent.move_state
				await get_tree().create_timer(0.2).timeout

func _on_animation_finished(anim_name: String) -> void:
	match anim_name:
		"Punch1", "Punch2":
			parent.animation_player.play("RESET")
			parent.state = GameCharacter.State.WALK
		"Kick1", "Kick2":
			move_state.walk_frame = 0
			parent.animation_player.play("RESET")
			parent.state = GameCharacter.State.WALK
		"TailWhip":
			move_state.walk_frame = 0
			if parent.inputs[GameCharacter.Inputs.YINPUT] > 0:
				parent.animation_player.play("Crouch")
			else:
				parent.animation_player.play("RESET")
			parent.state = GameCharacter.State.WALK
