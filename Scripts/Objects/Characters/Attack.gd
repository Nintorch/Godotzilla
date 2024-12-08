extends "res://Scripts/Objects/Characters/PlayerState.gd"

const MothraParticle := preload("res://Objects/Characters/MothraParticle.tscn")
const GodzillaHeatBeam := preload("res://Objects/Characters/GodzillaHeatBeam.tscn")

var move_state: Node
var variation := 0
var current_attack: PlayerCharacter.Attack

var attack_component: AttackComponent

var attack_functions: Dictionary = {
	# Common ground attacks
	PlayerCharacter.Attack.PUNCH: func() -> void:
		await player.attack.start_attack("Punch")
		,

	PlayerCharacter.Attack.KICK: func() -> void:
		await player.attack.start_attack("Kick")
		move_state.walk_frame = 0
		,

	# Godzilla-specific attacks
	PlayerCharacter.Attack.TAIL_WHIP: func() -> void:
		await player.attack.start_attack("TailWhip")
		move_state.walk_frame = 0
		if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0:
			player.animation_player.play("Crouch")
		else:
			player.animation_player.play("RESET")
		,
	
	PlayerCharacter.Attack.HEAT_BEAM: attack_heat_beam,
	
	# Mothra-specific attacks
	PlayerCharacter.Attack.EYE_BEAM: attack_eye_beam,
	PlayerCharacter.Attack.WING_ATTACK: attack_wing_attack,
}

#region State methods
func state_init() -> void:
	attack_component = player.attack
	move_state = player.state.states_list[player.move_state]
	
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
#endregion

func use(type: PlayerCharacter.Attack) -> void:
	var save_state := player.state.current
	player.state.current = PlayerCharacter.State.ATTACK
	current_attack = type
	player.animation_player.play("RESET")
	
	await attack_functions[type].call()
	
	player.state.current = save_state
			
# TODO: move the attacks to the player skin code
func attack_heat_beam() -> void:
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
	
func attack_eye_beam() -> void:
	var particle := MothraParticle.instantiate()
	Global.get_current_scene().add_child(particle)
	
	particle.setup(particle.Type.EYE_BEAM, player)
	particle.global_position = (
		player.global_position + Vector2(20 * player.direction, -2)
	)
	
	player.play_sfx("Step")
	player.state.current = player.move_state
	
func attack_wing_attack() -> void:
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
		
func wing_attack_sfx(times: int) -> void:
	for i in times:
		player.play_sfx("Step")
		await get_tree().create_timer(0.25, false).timeout
