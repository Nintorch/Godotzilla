class_name PlayerCharacter extends GameCharacter

#region General constants, variables and signals

enum Type {
	GODZILLA,
	MOTHRA,
}

# States in "States" node of the player should be
# in the same order as here.
enum State {
	WALK,
	FLY,
	LEVEL_INTRO,
	HURT,
	DEAD,
	ATTACK,
}

const SKINS: Array[Array] = [
	[
		"res://Objects/Characters/Godzilla/Godzilla.tscn",
		"res://Objects/Characters/Godzilla/GodzillaInfo.tres",
	],
	[
		"res://Objects/Characters/Mothra/Mothra.tscn",
		"res://Objects/Characters/Mothra/MothraInfo.tres",
	],
]

@export var character := PlayerCharacter.Type.GODZILLA

@export_enum("Right:1", "Left:-1")
var direction: int = 1:
	set(value):
		if value == 0:
			return
		direction = signi(value)
		if is_instance_valid(skin):
			skin.scale.x = direction
			attack.scale.x = direction

@export_category("Features")
## If not checked, then the PlayerCharacter is treated as a boss
## and not a character for the current player
@export var is_player := true
## Enable intro with steps and roaring, after which the player gets control and the level starts
@export var enable_intro := true
## If the attacks are not desired for the current level, uncheck this property
@export var enable_attacks := true
## If checked, the player can change the character's facing direction while moving left or right
@export var allow_direction_changing := false
@export var enable_bottomless_pits := true

@onready var attack: AttackComponent = $AttackComponent
@onready var state: StateMachine = $StateMachine

var move_state := State.WALK
var move_speed := 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var level := 1
var xp := 0
var save_position: Array[Vector2]
var _intro_ended := false
var _died_from_bottomless_pit := false

var body: AnimatedSprite2D
var skin: PlayerSkin
var animation_player: AnimationPlayer

signal character_ready
signal intro_ended
signal level_amount_changed(new_value: int, new_bar_count: int)
signal xp_amount_changed(new_value: int)

#endregion

func _ready() -> void:
	intro_ended.connect(func() -> void: _intro_ended = true)
	
	if is_player:
		Global.player = self
		if enable_intro:
			position.x = -40
	else:
		# The character is not a player, it's a boss/enemy
		health.enemy = true
		attack.enemy = true
			
	has_input = is_player
	
	inputs.resize(Inputs.size())
	inputs_pressed.resize(Inputs.size())
	setup_input(inputs)
	setup_input(inputs_pressed)
	
	save_position.resize(60)
			
	await Global.get_current_scene().ready
		
	# Skin creation and character-specific setup (inside of the skin's _init and _ready)
	change_skin(load(SKINS[character][0]).instantiate())
	load_state()

	# Setup for all characters
	direction = direction
	body = $Skin/Body
	animation_player = $Skin/AnimationPlayer
	
	if is_flying():
		animation_player.play("Idle")
	
	if not enable_intro:
		state.current = move_state
		if is_player:
			intro_ended.emit()
	
	state.init()
	character_ready.emit()
		
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if state.current != State.DEAD and not is_on_floor() and not is_flying():
		velocity.y += gravity * delta

	move_and_slide()
	save_position.pop_back()
	save_position.insert(0, Vector2(position))
	
	var camera := get_viewport().get_camera_2d()
	if state.current != State.DEAD and is_instance_valid(camera) and global_position.y > camera.limit_bottom - 16:
		health.set_value(0)
		_died_from_bottomless_pit = true

func _process(_delta: float) -> void:
	process_input()
	
func change_skin(new_skin: PlayerSkin) -> void:
	var prev_skin: Node2D = $Skin

	if prev_skin != null:
		remove_child(prev_skin)
		prev_skin.queue_free()
	
	new_skin.name = "Skin"
	add_child(new_skin)
	skin = new_skin
	setup_character(skin)
	
func setup_character(new_skin: PlayerSkin) -> void:
	set_collision(new_skin.get_node("Collision"))
	# Bar count is set on the board via the board piece character data
	move_state = new_skin.move_state
	move_speed = new_skin.move_speed * 60
	if state.current == State.LEVEL_INTRO and enable_intro:
		position.x = new_skin.intro_start_x
	if not _intro_ended:
		position.y += new_skin.intro_y_offset
	
	attack.hitboxes = new_skin.attack_hitboxes
	attack.attack_animation_player = new_skin.attack_animation_player
	attack.attacks.assign(new_skin.attacks)
	attack.attack_function_node = new_skin.attack_function_callback_node
	
#region Input related
	
# This is done so the bosses and players use the same script
# and to allow the developer/player to play as bosses/test their attacks.
enum Inputs {
	XINPUT, YINPUT, B, A, START, SELECT,
}

var has_input := true
var inputs := []
var inputs_pressed := []
const INPUT_ACTIONS := [["Left", "Right"], ["Up", "Down"], "B", "A", "Start", "Select"]
	
func setup_input(arr: Array) -> void:
	arr[Inputs.XINPUT] = 0
	arr[Inputs.YINPUT] = 0
	for i in range(Inputs.B, Inputs.size()):
		arr[i] = false
	
func process_input() -> void:
	if has_input:
		inputs[Inputs.XINPUT] = Input.get_axis(INPUT_ACTIONS[0][0], INPUT_ACTIONS[0][1])
		inputs[Inputs.YINPUT] = Input.get_axis(INPUT_ACTIONS[1][0], INPUT_ACTIONS[1][1])
		
		inputs_pressed[Inputs.XINPUT] = int(Input.is_action_just_pressed("Right")) \
			- int(Input.is_action_just_pressed("Left"))
		inputs_pressed[Inputs.YINPUT] = int(Input.is_action_just_pressed("Down")) \
			- int(Input.is_action_just_pressed("Up"))
			
		for i in range(Inputs.B, Inputs.size()):
			inputs[i] = Input.is_action_pressed(INPUT_ACTIONS[i])
			inputs_pressed[i] = Input.is_action_just_pressed(INPUT_ACTIONS[i])
			
func clear_inputs() -> void:
	inputs[Inputs.XINPUT] = 0.0
	inputs[Inputs.YINPUT] = 0.0
	
	inputs_pressed[Inputs.XINPUT] = 0
	inputs_pressed[Inputs.YINPUT] = 0
		
	for i in range(Inputs.B, Inputs.size()):
		inputs[i] = false
		inputs_pressed[i] = false

## Useful for boss attacks in AI code
func simulate_input_press(key: Inputs) -> void:
	inputs_pressed[key] = true
	await get_tree().process_frame
	inputs_pressed[key] = false
	
#endregion
	
## Set the current xp level
func set_level(value: int, sfx := false) -> void:
	if not is_player or level == value:
		return
	level = mini(value, 16)
	
	var bars := PlayerCharacter.calculate_bar_count(character, level)
	var bar_value := bars * 8
	
	power.max_value = bar_value
	power.value = bar_value
	health.resize_and_fill(bar_value)
	
	level_amount_changed.emit(level, bars)
	
	if sfx:
		get_sfx("LevelUp").play()
	
func add_xp(value: int) -> void:
	if value <= 0:
		return
		
	var xp_amount := calculate_xp_amount(level)
	var max_xp := calculate_xp_amount(16)
	var current_level := level
	xp += value
	if xp < max_xp:
		while xp >= xp_amount:
			xp -= xp_amount
			current_level += 1
			xp_amount = calculate_xp_amount(current_level)
		if current_level > level:
			set_level(current_level, true)
	else:
		xp = max_xp
		set_level(16)
		
	xp_amount_changed.emit(xp)
	
func get_sfx(sfx_name: String) -> AudioStreamPlayer:
	var path := "SFX/" + sfx_name
	if skin.has_node(path):
		return skin.get_node(path)
	return get_node(path)
	
## Play a sound effect from the list of PlayerCharacter scene's SFXs or character-specific SFXs via skins
func play_sfx(sfx_name: String) -> AudioStreamPlayer:
	var sfx := get_sfx(sfx_name)
	sfx.play()
	return sfx
	
func get_character_name() -> String:
	return skin.character_info.character_name
	
func is_flying() -> bool:
	return move_state == State.FLY
	
## Set the collision shape
func set_collision(shape: CollisionShape2D) -> void:
	get_children().map(func(c: Node) -> void:
		if c is CollisionShape2D:
			c.queue_free()
		)
	var new_shape: CollisionShape2D = shape.duplicate()
	new_shape.show()
	call_deferred("add_child", new_shape)
	
func is_hurtable() -> bool:
	return state.current not in [State.LEVEL_INTRO, State.HURT, State.DEAD]
	
func should_replay_after_death() -> bool:
	return _died_from_bottomless_pit

func _on_health_damaged(_amount: float, attack: AttackDescription) -> void:
	var attack_state := $StateMachine/Attack
	var hurt_state := $StateMachine/Hurt
	var hurt_time := attack.hurt_time if attack != null else -1.0
	if(state.current == State.ATTACK
		and attack_state.current_attack.name == "HeatBeam"):
			hurt_time = 0
		
	if hurt_time < 0:
		hurt_time = 0.6
	if hurt_time > 0:
		hurt_state.hurt_time = hurt_time
		state.current = State.HURT
		
	hurt_state.setup_from_attack(attack)
		
	if Global.controller_vibration and not Input.get_connected_joypads().is_empty():
		var device := Input.get_connected_joypads()[0]
		Input.start_joy_vibration(device, 0, 1, 0.4) # TODO: When we switch to Godot 4.6, swap these values
		
func _on_health_dead() -> void:
	state.current = State.DEAD
	power.set_empty()
	
## Load the character state from data from a board piece
func load_state(data: BoardPiece.CharacterData = null) -> void:
	super.load_state(data)
	
	var bar_value := 0
	if data == null:
		bar_value = PlayerCharacter.calculate_bar_count(character, level) * 8
		power.max_value = bar_value
		power.value = bar_value
		health.resize_and_fill(bar_value)
		return
		
	bar_value = data.bars * 8
	set_level(data.level)
	xp = data.xp
	
## Save the character state into a dictionary from a board piece
func save_state(data: BoardPiece.CharacterData = null) -> void:
	super.save_state(data)
	if data == null:
		return
	data.level = level
	data.xp = xp

func _on_attack_component_attacked(attacked_body: Node2D, attack: AttackDescription) -> void:
	if attacked_body is Enemy:
		add_xp(5)
		Global.add_score(int(20 * attack.damage_amount))
		
static func get_character_info(char_id: PlayerCharacter.Type) -> CharacterInfo:
	return load(SKINS[char_id][1])
		
static func calculate_bar_count(char_id: PlayerCharacter.Type, char_level: int) -> int:
	return get_character_info(char_id).bar_count + char_level - 1
	
static func calculate_xp_amount(char_level: int) -> int:
	return 100 + 50 * (char_level - 1)

static func get_character_name_static(char_id: PlayerCharacter.Type) -> String:
	return get_character_info(char_id).character_name
