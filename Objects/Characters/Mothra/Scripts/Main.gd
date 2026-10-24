extends PlayerSkin

var attack_timer := Timer.new()

func _ready() -> void:
	super._ready()
	attack_timer.one_shot = true
	add_child(attack_timer)

func fly_process() -> void:
	if player.character == PlayerCharacter.Type.MOTHRA:
		if (player.inputs_pressed[player.Inputs.A]
			or player.inputs_pressed[player.Inputs.B]) \
			and attack_timer.is_stopped():
				player.attack.start_attack("EyeBeam")
				attack_timer.start(0.2)
		
		if player.inputs_pressed[player.Inputs.START]:
			player.attack.start_attack("WingAttack")

#region Attacks
const MothraParticle := preload("res://Objects/Characters/Mothra/MothraParticle.tscn")

# These functions are referenced in the "Attacks" property of the skin object

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
		if not attack_state_node.is_still_attacking(): return
		
	player.state.current = player.move_state
		
func wing_attack_sfx(times: int) -> void:
	for i in times:
		player.play_sfx("Step")
		await get_tree().create_timer(0.25, false).timeout
#endregion
