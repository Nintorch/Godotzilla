extends PlayerSkin

@onready var offset_y: float = $Body/Head.position.y
@onready var body := $Body
@onready var head := $Body/Head

func _init() -> void:
	character_name = "Godzilla"
	bar_count = 6
	walk_frame_speed = 9

func _ready() -> void:
	player.get_sfx("Step").stream = preload("res://Audio/SFX/GodzillaStep.wav")
	player.get_sfx("Roar").stream = preload("res://Audio/SFX/GodzillaRoar.wav")
	player.move_state = PlayerCharacter.State.WALK
	if player.is_player and player.enable_intro:
		player.position.x = -35

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
			player.use_attack(PlayerCharacter.Attack.TAIL_WHIP)
	if player.inputs_pressed[PlayerCharacter.Inputs.START] \
		and player.power.value >= 6 * 8:
		player.use_attack(PlayerCharacter.Attack.HEAT_BEAM)

func _on_animation_started(anim_name: StringName) -> void:
	var collision: CollisionShape2D = $Collision
	if anim_name == "Crouch" or anim_name == "TailWhip":
		collision = $CrouchCollision
	player.set_collision(collision)
