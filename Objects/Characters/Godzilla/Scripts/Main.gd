extends PlayerSkin

@onready var offset_y: float = $Body/Head.position.y
@onready var body := $Body
@onready var head := $Body/Head

func _ready() -> void:
	super._ready()
	player.attack.attack_finished.connect(func(a: AttackDescription) -> void:
		if a.name == "TailWhip":
			attack_tail_whip_after()
		)

func _process(_delta: float) -> void:
	if body.animation == "Idle":
		if body.frame == 2 or body.frame == 6:
			head.position.y = offset_y + 1
		else:
			head.position.y = offset_y
		
		if head.animation == "Idle":
			head.frame = body.frame

func walk_process() -> void:
	common_ground_attacks()
	if player.animation_player.current_animation == "Crouch" \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]:
			player.attack.start_attack("TailWhip")
	if player.inputs_pressed[PlayerCharacter.Inputs.START] \
		and player.power.value >= 6 * 8:
		player.attack.start_attack("HeatBeam")

func _on_animation_started(anim_name: StringName) -> void:
	var collision: CollisionShape2D = $Collision
	if anim_name == "Crouch" or anim_name == "TailWhip":
		collision = $CrouchCollision
	player.set_collision(collision)

#region Attacks
const GodzillaHeatBeam := preload("uid://twku26u8n2dy")

func attack_tail_whip_after() -> void:
	move_state_node.walk_frame = 0
	if player.inputs[PlayerCharacter.Inputs.YINPUT] > 0:
		player.animation_player.play("Crouch")
	else:
		player.animation_player.play("RESET")

# This function is referenced in the "Attacks" property of the skin object
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
		if not attack_state_node.is_still_attacking(): return
		
	move_state_node.walk_frame = 0
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
#endregion
