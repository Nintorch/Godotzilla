extends "res://Scripts/Objects/Characters/State.gd"

const MothraParticle := preload("res://Objects/Characters/MothraParticle.tscn")
const GodzillaHeatBeam := preload("res://Objects/Characters/GodzillaHeatBeam.tscn")

var move_state: Node
var current_attack = GameCharacter.Attack
var variation = 0

func state_init() -> void:
	move_state = parent.states_list[parent.move_state]
	parent.animation_player.connect("animation_finished", _on_animation_finished)
	
var save_allow_direction_changing := false
func state_entered() -> void:
	save_allow_direction_changing = parent.allow_direction_changing
	parent.allow_direction_changing = false

func state_exited() -> void:
	parent.allow_direction_changing = save_allow_direction_changing

func _process(delta: float) -> void:
	move_state.move(delta)

func use(type: GameCharacter.Attack) -> void:
	parent.state = GameCharacter.State.ATTACK
	current_attack = type
	
	match type:
		GameCharacter.Attack.PUNCH, GameCharacter.Attack.KICK:
			parent.animation_player.play("RESET")
			await get_tree().process_frame
	
	match type:
		# Common ground attacks
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
			
		# Godzilla-specific attacks
		GameCharacter.Attack.TAIL_WHIP:
			parent.animation_player.play("TailWhip")
			
		GameCharacter.Attack.HEAT_BEAM:
			var animations = [
				["HeatBeam1", 0.1],
				["HeatBeam2", 1],
				["HeatBeam1", 0.1],
				["HeatBeam3", 1],
			]
			
			for anim in animations:
				parent.animation_player.play(anim[0])
				if anim[0] == "HeatBeam3":
					create_heat_beam()
				await get_tree().create_timer(anim[1], false).timeout
				
			move_state.walk_frame = 0
			parent.animation_player.play("RESET")
			parent.state = parent.move_state
			
		# Mothra-specific attacks
		GameCharacter.Attack.EYE_BEAM:
			var particle = MothraParticle.instantiate()
			Global.get_current_scene().add_child(particle)
			particle.setup(particle.Type.EYE_BEAM, parent)
			particle.global_position = \
				parent.global_position + Vector2(20 * parent.scale.x, -2)
			parent.state = parent.move_state
			
		GameCharacter.Attack.WING_ATTACK:
			var power = mini(parent.power.value, 2 * 8)
			var times: int = power / 2.6
			if times == 0:
				parent.state = parent.move_state
				return
			parent.power.use(power)
			
			wing_attack_sfx()
			for i in times:
				var particle := MothraParticle.instantiate()
				Global.get_current_scene().add_child(particle)
				particle.setup(particle.Type.WING, parent)
				particle.global_position = parent.global_position
				await get_tree().create_timer(0.15, false).timeout
				
			parent.state = parent.move_state
				
func create_heat_beam() -> void:
	const HEAT_BEAM_COUNT := 12
	var heat_beams: Array[AnimatedSprite2D] = []
	parent.power.use(6 * 8)
	
	for i in HEAT_BEAM_COUNT:
		var particle := GodzillaHeatBeam.instantiate()
		particle.setup(i, parent)
		particle.position = Vector2(26, 0) + Vector2(8, 0) * i
		parent.add_child(particle)
		heat_beams.append(particle)
		
	for i in HEAT_BEAM_COUNT:
		heat_beams[i].start()
		await get_tree().create_timer(0.01, false).timeout
		
func wing_attack_sfx() -> void:
	for i in 3:
		parent.get_sfx("Step").play()
		await get_tree().create_timer(0.25, false).timeout

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
