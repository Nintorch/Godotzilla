extends "res://Scripts/Objects/Characters/PlayerState.gd"

const MothraParticle := preload("res://Objects/Characters/MothraParticle.tscn")
const GodzillaHeatBeam := preload("res://Objects/Characters/GodzillaHeatBeam.tscn")

var move_state: Node
var current_attack: PlayerCharacter.Attack
var variation := 0

var attack_component: AttackComponent

func state_init() -> void:
	attack_component = player.attack
	move_state = player.state.states_list[player.move_state]
	player.animation_player.animation_finished.connect(_on_animation_finished)
	
var save_allow_direction_changing := false
func state_entered() -> void:
	save_allow_direction_changing = player.allow_direction_changing
	player.allow_direction_changing = false
	
func state_exited() -> void:
	player.allow_direction_changing = save_allow_direction_changing
	attack_component.stop_attack()
	
func is_still_attacking() -> bool:
	return player.state.current == PlayerCharacter.State.ATTACK

func _process(delta: float) -> void:
	# Allow the player to move while attacking
	move_state.move(delta)

func use(type: PlayerCharacter.Attack) -> void:
	player.state.current = PlayerCharacter.State.ATTACK
	current_attack = type
	
	match type:
		PlayerCharacter.Attack.PUNCH, PlayerCharacter.Attack.KICK:
			player.animation_player.play("RESET")
			await get_tree().process_frame
	
	match type:
		# Common ground attacks
		PlayerCharacter.Attack.PUNCH:
			player.play_sfx("Punch")
			player.attack.start_attack("Punch")

		PlayerCharacter.Attack.KICK:
			player.play_sfx("Punch")
			player.attack.start_attack("Kick")
			
		# Godzilla-specific attacks
		PlayerCharacter.Attack.TAIL_WHIP:
			player.attack.start_attack("TailWhip")
			
		PlayerCharacter.Attack.HEAT_BEAM:
			var animations := [
				["HeatBeam1", 0.1],
				["HeatBeam2", 1],
				["HeatBeam1", 0.1],
				["HeatBeam3", 1],
			]
			
			for anim: Array in animations:
				player.animation_player.play(anim[0] as String)
				
				if anim[0] == "HeatBeam3":
					create_heat_beam()
					player.play_sfx("HeatBeam")
					
				await get_tree().create_timer(anim[1], false).timeout
				if not is_still_attacking(): return
				
			move_state.walk_frame = 0
			player.animation_player.play("RESET")
			player.state.current = player.move_state
			
		# Mothra-specific attacks
		PlayerCharacter.Attack.EYE_BEAM:
			var particle := MothraParticle.instantiate()
			Global.get_current_scene().add_child(particle)
			
			particle.setup(particle.Type.EYE_BEAM, player)
			particle.global_position = (
				player.global_position + Vector2(20 * player.direction, -2)
			)
			
			player.state.current = player.move_state
			player.play_sfx("Step")
			
		PlayerCharacter.Attack.WING_ATTACK:
			# Calculate the amount of power this attack should use
			var power := mini(player.power.value, 2 * 8)
			
			# Calculate the number of wing particles that should be created
			var times := int(power / 2.6)
			
			# Not enough power for this attack
			if times == 0:
				player.state.current = player.move_state
				return
				
			player.power.use(power)
			
			wing_attack_sfx(mini(3, times))
			
			for i in times:
				var particle := MothraParticle.instantiate()
				Global.get_current_scene().add_child(particle)
				
				particle.setup(particle.Type.WING, player)
				particle.global_position = player.global_position
				
				await get_tree().create_timer(0.15, false).timeout
				if not is_still_attacking(): return
				
			player.state.current = player.move_state
				
func create_heat_beam() -> void:
	const HEAT_BEAM_COUNT := 12
	var heat_beams: Array[AnimatedSprite2D] = []
	player.power.use(6 * 8)
	
	for i in HEAT_BEAM_COUNT:
		var particle := GodzillaHeatBeam.instantiate()
		
		particle.setup(i, player)
		particle.position = Vector2(26, 0) + Vector2(8, 0) * i
		particle.position.x *= player.direction
		particle.scale.x = player.direction
		particle.particle_array = heat_beams
		
		player.add_child(particle)
		heat_beams.append(particle)
		
	for i in HEAT_BEAM_COUNT:
		heat_beams[i].start()
		await get_tree().create_timer(0.01, false).timeout
		
func wing_attack_sfx(times: int) -> void:
	for i in times:
		player.play_sfx("Step")
		await get_tree().create_timer(0.25, false).timeout

func _on_animation_finished(anim_name: String) -> void:
	if not is_still_attacking(): return
	match anim_name:
		"Punch1", "Punch2":
			player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
		"Kick1", "Kick2":
			move_state.walk_frame = 0
			player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
		"TailWhip":
			move_state.walk_frame = 0
			if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0:
				player.animation_player.play("Crouch")
			else:
				player.animation_player.play("RESET")
			player.state.current = PlayerCharacter.State.WALK
