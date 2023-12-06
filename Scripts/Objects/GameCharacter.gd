class_name GameCharacter
extends CharacterBody2D

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

enum Attack {
	# Attacks that are common for ground characters
	PUNCH,
	KICK,
	
	# Godzilla attacks
	TAIL_WHIP,
	HEAT_BEAM,
	
	# Mothra attacks
	EYE_BEAM,
	WING_ATTACK,
}

const CHARACTER_NAMES: Array[String] = [
	"Godzilla",
	"Mothra",
]

const BaseBarCount: Array[int] = [
	6, # Godzilla
	8, # Mothra
]

@export var is_player := true
@export var enable_intro := true

@onready var collision: CollisionShape2D = $Collision
# TODO: reusable state machine
@onready var states_list: Array[Node] = $States.get_children()
@onready var health: Node = $HealthComponent

var power_bar: Control
var life_bar: Control
var level_node: Label
var board_piece: Node2D # Set in Board.gd

var state := State.LEVEL_INTRO: set = _set_state
var move_state := State.WALK

var character := GameCharacter.Type.GODZILLA
var move_speed := 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var level := 1
var direction := 1
var score := 0
var save_position: Array[Vector2]

var body: AnimatedSprite2D
var animation_player: AnimationPlayer

# This is done so the bosses and players use the same script
# and allow to play as bosses and test their attacks.
enum Inputs {
	XINPUT, YINPUT, B, A, START, SELECT,
}

var has_input := true
var inputs := []
var inputs_pressed := []
const INPUT_ACTIONS = [["Left", "Right"], ["Up", "Down"], "B", "A", "Start", "Select"]

# TODO: change the amount of bars of power and life based on the character level
# same with health component hp

# TODO: save bars as variable and skip everything bar-related if are no bars
# save power as variable

signal intro_ended

func _ready() -> void:
	if is_player:
		Global.player = self
		if enable_intro:
			position.x = -40
	
	inputs.resize(Inputs.size())
	inputs_pressed.resize(Inputs.size())
	save_position.resize(60)
	
	# Several default values
	move_speed = 1 * 60
			
	await Global.get_current_scene().ready
	
	if is_player:
		var hud: CanvasLayer = Global.get_current_scene().get_HUD()
		if not power_bar:
			power_bar = hud.get_node("PlayerCharacter/Power")
		if not life_bar:
			life_bar = hud.get_node("PlayerCharacter/Life")
		if not level_node:
			level_node = hud.get_node("PlayerCharacter/Level")
			
	load_state()
		
	# GameCharacter-specific setup	
	var skin: Node2D
	match character:
		GameCharacter.Type.GODZILLA:
			# Skin is already Godzilla, so we just move it above everything else
			move_child($Skin, -1)
			get_sfx("Step").stream = load("res://Audio/SFX/GodzillaStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.ogg")
			move_state = State.WALK
			set_collision(Vector2(20, 56), Vector2(0, -1))
			
			# We set the character-specific position so when the character
			# walks in a sudden frame change won't happen
			# (walk_frame is set to 0 when the characters gets control)
			if is_player and enable_intro:
				position.x = -35
		
		GameCharacter.Type.MOTHRA:
			skin = preload("res://Objects/Characters/Mothra.tscn").instantiate()
			get_sfx("Step").stream = load("res://Audio/SFX/MothraStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.ogg")
			move_state = State.FLY
			position.y -= 40
			move_speed = 2 * 60
			set_collision(Vector2(36, 14), Vector2(-4, 1))
			
			if is_player and enable_intro:
				position.x = -37
			
	# Setup for all characters
	if skin:
		var prev_skin: Node2D = $Skin
		remove_child(prev_skin)
		prev_skin.queue_free()
		
		skin.name = "Skin"
		add_child(skin)
	
	body = $Skin/Body
	animation_player = $Skin/AnimationPlayer
	move_child(collision, -1)
	
	if is_flying():
		animation_player.play("Idle")
	
	if not enable_intro:
		state = move_state
		if is_player:
			intro_ended.emit()
	
	for i in states_list:
		i.state_init()
		if i == states_list[state]:
			i.enable()
			i.state_entered()
		else:
			i.disable()
		
func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 20 == 0 \
		and power_bar.target_value < power_bar.max_value:
		power_bar.target_value += 1.0
		
	# The character should come from outside the camera from the left side
	# of the screen, so we shouldn't limit the position unless the player
	# got control of the character.
	if velocity.x < 0 \
		and position.x <= get_viewport().get_camera_2d().limit_left + 16:
		position.x = get_viewport().get_camera_2d().limit_left + 16
		velocity.x = 0

	if state != State.DEAD and not is_on_floor() and not is_flying():
		velocity.y += gravity * delta

	move_and_slide()
	save_position.pop_back()
	save_position.insert(0, Vector2(position))

func _process(_delta: float) -> void:
	process_input()

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	
	var old_state_node := states_list[state]
	var new_state_node := states_list[new_state]
	
	old_state_node.state_exited()
	old_state_node.disable()
	new_state_node.enable()
	new_state_node.state_entered()
	
	state = new_state
	
func process_input() -> void:
	if has_input:
		inputs[Inputs.XINPUT] = roundi(Input.get_axis(INPUT_ACTIONS[0][0], INPUT_ACTIONS[0][1]))
		inputs[Inputs.YINPUT] = roundi(Input.get_axis(INPUT_ACTIONS[1][0], INPUT_ACTIONS[1][1]))
		
		inputs_pressed[Inputs.XINPUT] = int(Input.is_action_just_pressed("Right")) \
			- int(Input.is_action_just_pressed("Left"))
		inputs_pressed[Inputs.YINPUT] = int(Input.is_action_just_pressed("Down")) \
			- int(Input.is_action_just_pressed("Up"))
			
		for i in range(Inputs.B, Inputs.size()):
			inputs[i] = Input.is_action_pressed(INPUT_ACTIONS[i])
			inputs_pressed[i] = Input.is_action_just_pressed(INPUT_ACTIONS[i])
	
# TODO: attack component
func use_attack(type: Attack) -> void:
	$States/Attack.use(type)
	
func set_level(value: int) -> void:
	if not is_player or level == value:
		return
	level = value
	var level_str := str(level)
	if level_str.length() < 2:
		level_str = "0" + level_str
	level_node.text = "level " + level_str
	
	var bars := GameCharacter.calculate_bar_count(character, level)
	var bar_value := bars * 8
	power_bar.width = bars
	power_bar.target_value = bar_value
	life_bar.width = bars
	life_bar.target_value = bar_value
	health.hp = bar_value
	health.hp_max = bar_value
		
func use_power(amount: int) -> bool:
	if get_power() < amount:
		return false
	power_bar.target_value -= amount
	return true
	
func get_power() -> int:
	return power_bar.target_value
	
# Pass 0 to update the score meter
func add_score(amount: int) -> void:
	if not is_player:
		return

	var score_meter: Label = \
		Global.get_current_scene().\
		get_HUD().get_node("PlayerCharacter/ScoreMeter")
	score += amount
	if is_player:
		score_meter.text = str(score)
	
func get_sfx(sfx_name: String) -> AudioStreamPlayer:
	return get_node("SFX/" + sfx_name)
	
func get_character_name() -> String:
	return CHARACTER_NAMES[character]
	
func is_flying() -> bool:
	return character == Type.MOTHRA
	
func set_collision(size: Vector2, offset: Vector2) -> void:
	collision.shape.size = size
	collision.position = offset
	
func is_hurtable() -> bool:
	return state not in [State.LEVEL_INTRO, State.HURT, State.DEAD]

func _on_health_damaged(amount: float, hurt_time: float) -> void:
	life_bar.target_value -= amount
	if hurt_time < 0:
		hurt_time = 0.6
	if hurt_time > 0:
		$States/Hurt.hurt_time = hurt_time
		state = State.HURT

func _on_health_dead() -> void:
	life_bar.target_value = 0
	state = State.DEAD

func _on_health_healed(amount: float) -> void:
	life_bar.target_value += amount
	
func load_state() -> void:
	if not board_piece:
		var bars := GameCharacter.calculate_bar_count(character, level)
		power_bar.width = bars
		life_bar.width = bars
		return
		
	var data: Dictionary = board_piece.character_data
	set_level(board_piece.level)
	health.hp = data.hp
	health.hp_max = data.bars * 8
	
	power_bar.width = data.bars
	life_bar.width = data.bars
	life_bar.initial_value = data.hp
	
	score = Global.board.board_data.player_score
	add_score(0)
	
	# TODO: xp
	
func save_state() -> void:
	if not board_piece:
		return
		
	board_piece.character_data.hp = health.hp
	board_piece.character_data.bars = power_bar.width
	board_piece.level = level
	Global.board.board_data.player_score = score
	Global.board.board_data.player_level[board_piece] = level

static func calculate_bar_count(char_id: GameCharacter.Type, char_level: int) -> int:
	return BaseBarCount[char_id] + char_level - 1
