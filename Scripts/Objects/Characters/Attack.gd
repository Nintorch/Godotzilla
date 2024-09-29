extends State

const MothraParticle := preload("res://Objects/Characters/MothraParticle.tscn")
const GodzillaHeatBeam := preload("res://Objects/Characters/GodzillaHeatBeam.tscn")

var move_state: Node
var current_attack: PlayerCharacter.Attack
var variation := 0

var attack_component: AttackComponent

func state_init() -> void:
	attack_component = parent.attack
	move_state = parent.state.states_list[parent.move_state]
	parent.animation_player.animation_finished.connect(_on_animation_finished)
	
var save_allow_direction_changing := false
func state_entered() -> void:
	save_allow_direction_changing = parent.allow_direction_changing
	parent.allow_direction_changing = false

func state_exited() -> void:
	parent.allow_direction_changing = save_allow_direction_changing
	
func is_still_attacking() -> bool:
	return parent.state.current == PlayerCharacter.State.ATTACK

func _process(delta: float) -> void:
	# Allow the player to move while attacking
	move_state.move(delta)

func use(type: PlayerCharacter.Attack) -> void:
	parent.state.current = PlayerCharacter.State.ATTACK
	current_attack = type
	
	match type:
		PlayerCharacter.Attack.PUNCH, PlayerCharacter.Attack.KICK:
			parent.animation_player.play("RESET")
			await get_tree().process_frame
	
	match type:
		# Common ground attacks
		PlayerCharacter.Attack.PUNCH:
			variation = not variation
			parent.animation_player.play("Punch1" if variation else "Punch2")
			parent.get_sfx("Punch").play()
			
			attack_component.set_collision(Vector2(30, 20), Vector2(20 * parent.direction, -15))
			
			attack_component.start_attack(2)
			await parent.animation_player.animation_finished
			attack_component.stop_attack()

		PlayerCharacter.Attack.KICK:
			variation = not variation
			parent.animation_player.play("Kick1" if variation else "Kick2")
			parent.get_sfx("Punch").play()
			
			attack_component.set_collision(Vector2(30, 20), Vector2(20 * parent.direction, 15))
			
			attack_component.start_attack(2)
			await parent.animation_player.animation_finished
			attack_component.stop_attack()
			
		# Godzilla-specific attacks
		PlayerCharacter.Attack.TAIL_WHIP:
			parent.animation_player.play("TailWhip")
			await get_tree().create_timer(0.15, false).timeout
			if not is_still_attacking(): return
			
			attack_component.set_collision(Vector2(50, 40), Vector2(30 * parent.direction, 5))
			
			attack_component.start_attack(2)
			await parent.animation_player.animation_finished
			attack_component.stop_attack()
			
		PlayerCharacter.Attack.HEAT_BEAM:
			var animations := [
				["HeatBeam1", 0.1],
				["HeatBeam2", 1],
				["HeatBeam1", 0.1],
				["HeatBeam3", 1],
			]
			
			for anim: Array in animations:
				parent.animation_player.play(anim[0] as String)
				
				if anim[0] == "HeatBeam3":
					create_heat_beam()
					parent.get_sfx("HeatBeam").play()
					
				await get_tree().create_timer(anim[1], false).timeout
				if not is_still_attacking(): return
				
			move_state.walk_frame = 0
			parent.animation_player.play("RESET")
			parent.state.current = parent.move_state
			
		# Mothra-specific attacks
		PlayerCharacter.Attack.EYE_BEAM:
			var particle := MothraParticle.instantiate()
			Global.get_current_scene().add_child(particle)
			
			particle.setup(particle.Type.EYE_BEAM, parent)
			particle.global_position = (
				parent.global_position + Vector2(20 * parent.direction, -2)
			)
			
			parent.state.current = parent.move_state
			parent.get_sfx("Step").play()
			
		PlayerCharacter.Attack.WING_ATTACK:
			# Calculate the amount of power this attack should use
			var power := mini(parent.power.value, 2 * 8)
			
			# Calculate the number of wing particles that should be created
			var times := int(power / 2.6)
			
			# Not enough power for this attack
			if times == 0:
				parent.state.current = parent.move_state
				return
				
			parent.power.use(power)
			
			wing_attack_sfx(mini(3, times))
			
			for i in times:
				var particle := MothraParticle.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.WING, parent)
				particle.global_position = parent.global_position
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			parent.state.current = parent.move_state
				
func create_heat_beam() -> void:
	const HEAT_BEAM_COUNT := 12
	var heat_beams: Array[AnimatedSprite2D] = []
	parent.power.use(6 * 8)
	
	for i in HEAT_BEAM_COUNT:
		var particle := GodzillaHeatBeam.instantiate()
		
		particle.setup(i, parent)
		particle.position = Vector2(26, 0) + Vector2(8, 0) * i
		particle.position.x *= parent.direction
		particle.scale.x = parent.direction
		particle.particle_array = heat_beams
		
		parent.add_child(particle)
		heat_beams.append(particle)
		
	for i in HEAT_BEAM_COUNT:
		heat_beams[i].start()
		await get_tree().create_timer(0.01, false).timeout
		
func wing_attack_sfx(times: int) -> void:
	for i in times:
		parent.get_sfx("Step").play()
		await get_tree().create_timer(0.25, false).timeout

func _on_animation_finished(anim_name: String) -> void:
	if not is_still_attacking(): return
	match anim_name:
		"Punch1", "Punch2":
			parent.animation_player.play("RESET")
			parent.state.current = PlayerCharacter.State.WALK
		"Kick1", "Kick2":
			move_state.walk_frame = 0
			parent.animation_player.play("RESET")
			parent.state.current = PlayerCharacter.State.WALK
		"TailWhip":
			move_state.walk_frame = 0
			if parent.inputs[PlayerCharacter.Inputs.YINPUT] > 0:
				parent.animation_player.play("Crouch")
			else:
				parent.animation_player.play("RESET")
			parent.state.current = PlayerCharacter.State.WALK
