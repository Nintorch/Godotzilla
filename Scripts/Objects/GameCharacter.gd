class_name GameCharacter
extends CharacterBody2D

enum Type {
	GODZILLA,
	MOTHRA,
}

const CharacterNames: Array[String] = [
	"Godzilla",
	"Mothra",
]

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
	HEAT_BEAM, # TODO
}

@export var is_player := true
@export var enable_intro := true

@onready var collision: CollisionShape2D = $Collision
@onready var states_list: Array[Node] = $States.get_children()
@onready var health: Node = $Health

var power_bar: Control
var life_bar: Control
var level_node: Label

var state := State.LEVEL_INTRO
var move_state := State.WALK

var character := GameCharacter.Type.GODZILLA
var move_speed := 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var level := 1
var direction := 1
var score := 0

var body: AnimatedSprite2D
var animation_player: AnimationPlayer

# This is done so the bosses and players use the same script
# and allowing to play as bosses and test their attacks.
enum Inputs {
	XINPUT, YINPUT, B, A, START, SELECT,
}

# Check if the character can be controlled by the player,
# if not, then that's probably not the player character and therefore
# cannot change any player's HUD properties.
var has_input := true
var inputs := []
var inputs_pressed := []
const INPUT_ACTIONS = [["Left", "Right"], ["Up", "Down"], "B", "A", "Start", "Select"]

# TODO: change the amount of bars of power and life based on the character level
# same with health component hp

func _ready() -> void:
	if is_player:
		Global.player = self
		if enable_intro:
			position.x = -40
	
	inputs.resize(Inputs.size())
	inputs_pressed.resize(Inputs.size())
	
	# Several default values
	move_speed = 1 * 60
			
	await Global.get_current_scene().ready
	
	if is_player:
		var hud = Global.get_current_scene().get_HUD()
		if not power_bar:
			power_bar = hud.get_node("PlayerCharacter/Power")
		if not life_bar:
			life_bar = hud.get_node("PlayerCharacter/Life")
		if not level_node:
			level_node = hud.get_node("PlayerCharacter/Level")
			
		health.hp = life_bar.max_value
		health.hp_max = life_bar.max_value
	
	# GameCharacter-specific setup	
	var skin: Node2D
	match character:
		GameCharacter.Type.GODZILLA:
			# Skin is already Godzilla, so we just move it above everything else
			move_child($Skin, -1)
			get_sfx("Step").stream = load("res://Audio/SFX/GodzillaStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.wav")
			move_state = State.WALK
			
			# We set the character-specific position so when the character
			# walks in a sudden frame change won't happen
			# (walk_frame is set to 0 when the characters gets control)
			if is_player and enable_intro:
				position.x = -35
		
		GameCharacter.Type.MOTHRA:
			skin = preload("res://Objects/Characters/Mothra.tscn").instantiate()
			get_sfx("Step").stream = load("res://Audio/SFX/GodzillaStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.wav")
			move_state = State.FLY
			position.y -= 40
			move_speed = 2 * 60
			set_collision(Vector2(36, 14), Vector2(-4, 1))
			
	# Setup for all characters
	if skin:
		var prev_skin = $Skin
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
			Global.get_current_scene().intro_ended()
	
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
	if state != State.LEVEL_INTRO and velocity.x < 0 \
		and position.x <= Global.camera.limit_left + 16:
		position.x = Global.camera.limit_left + 16
		velocity.x = 0

	if state != State.DEAD and not is_on_floor() and not is_flying():
		velocity.y += gravity * delta

	move_and_slide()

func _process(_delta: float) -> void:
	process_input()
	
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

func set_state(new_state: State) -> void:
	if state == new_state:
		return
	
	var old_state_node = states_list[state]
	var new_state_node = states_list[new_state]
	
	old_state_node.state_exited()
	old_state_node.disable()
	new_state_node.enable()
	new_state_node.state_entered()
	
	state = new_state
	
func use_attack(type: Attack):
	$States/Attack.use(type)
	
func set_level(value: int) -> void:
	if not is_player:
		return
	level = value
	var level_str = str(level)
	if level_str.length() < 2:
		level_str = "0" + level_str
	level_node.text = "level " + level_str
		
func use_power(amount: int) -> bool:
	if power_bar.target_value < amount:
		return false
	power_bar.target_value -= amount
	return true
	
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
	return CharacterNames[character]
	
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
		set_state(State.HURT)

func _on_health_dead() -> void:
	life_bar.target_value = 0
	set_state(State.DEAD)

func _on_health_healed(amount: float) -> void:
	life_bar.target_value += amount
