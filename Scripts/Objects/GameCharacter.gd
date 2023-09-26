class_name GameCharacter
extends CharacterBody2D

enum Type {
	GODZILLA,
	MOTHRA, # To be added
}

const CharacterNames: Array[String] = [
	"Godzilla",
	"Mothra",
]

# States in "States" node of the player should be
# in the same order as in here.
enum State {
	MOVE,
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
}

@onready var states_list: Array[Node] = $States.get_children()
var state = State.LEVEL_INTRO

var character = GameCharacter.Type.GODZILLA
var move_speed = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var level = 1
var direction = 1

var body: AnimatedSprite2D
var animation_player: AnimationPlayer

# This is done so the bosses and players use the same script
# and allowing to play as bosses and test their attacks.
enum Inputs {
	XINPUT, YINPUT, B, A, START, SELECT,
	
	COUNT,  # Not an input action but just a constant
}

var inputs := []
var inputs_pressed := []
var has_input := true
const INPUT_ACTIONS = [["Left", "Right"], ["Up", "Down"], "B", "A", "Start", "Select"]

func _ready() -> void:
	# We don't set the player reference to the current character
	# in case if it doesn't have input (it's most likely a boss).
	if has_input:
		Global.player = self
	
	inputs.resize(Inputs.COUNT)
	inputs_pressed.resize(Inputs.COUNT)
	
	# Several default values
	move_speed = 1 * 60
	position.x = -40
	
	# GameCharacter-specific setup
	var skin: Node2D
	match character:
		GameCharacter.Type.GODZILLA:
			skin = preload("res://Objects/Characters/Godzilla.tscn").instantiate()
			get_sfx("Step").stream = load("res://Audio/SFX/GodzillaStep.ogg")
			get_sfx("Roar").stream = load("res://Audio/SFX/GodzillaRoar.wav")
			# We set the character-specific position so when the character
			# walks in a sudden frame change won't happen
			# (walk_frame is set to 0 when the characters gets control)
			position.x = -35
			
	# Setup for all characters
	var prev_skin = $Skin
	remove_child(prev_skin)
	prev_skin.queue_free()
	
	skin.name = "Skin"
	add_child(skin)
	
	body = $Skin/Body
	animation_player = $Skin/AnimationPlayer
	
	for i in states_list:
		var enable = i == states_list[state]
		i.set_process(enable)
		i.set_physics_process(enable)
		i.set_process_input(enable)
		
		i.state_init()
		if enable:
			i.state_entered()
		
func _physics_process(delta: float) -> void:
	# The character should come from outside the camera from the left side
	# of the screen, so we shouldn't limit the position unless the player
	# got control of the character.
	if state != State.LEVEL_INTRO and velocity.x < 0 \
		and position.x <= Global.camera.limit_left + 16:
		position.x = Global.camera.limit_left + 16
		velocity.x = 0

	if state != State.DEAD and not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _process(_delta: float) -> void:
	process_input()
	set_level(level)
	
	if Engine.get_physics_frames() % 20 == 0 \
		and get_power_bar().target_value < get_power_bar().max_value:
		get_power_bar().target_value += 1.0
		
	if get_life_bar().value <= 0:
		set_state(State.DEAD)
	
func process_input() -> void:
	if has_input:
		inputs[Inputs.XINPUT] = Input.get_axis(INPUT_ACTIONS[0][0], INPUT_ACTIONS[0][1])
		inputs[Inputs.YINPUT] = Input.get_axis(INPUT_ACTIONS[1][0], INPUT_ACTIONS[1][1])
					
		inputs_pressed[Inputs.XINPUT] = int(Input.is_action_just_pressed("Right")) \
			- int(Input.is_action_just_pressed("Left"))
		inputs_pressed[Inputs.YINPUT] = int(Input.is_action_just_pressed("Down")) \
			- int(Input.is_action_just_pressed("Up"))
			
		for i in range(Inputs.B, Inputs.COUNT):
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

func get_power_bar():
	return Global.level.get_HUD().get_node("PlayerCharacter/Power")
	
func get_life_bar():
	return Global.level.get_HUD().get_node("PlayerCharacter/Life")
	
func set_level(value: int) -> void:
	if not has_input:
		return
	level = value
	var level_str = str(level)
	if level_str.length() < 2:
		level_str = "0" + level_str
	Global.level.get_HUD().get_node("PlayerCharacter/Level").text = "level " + level_str
	
# TODO: damage time
func damage(amount: int, hurt_anim := true) -> void:
	if not is_hurtable():
		return
	get_life_bar().target_value -= amount
	if get_life_bar().target_value <= 0:
		get_life_bar().target_value = 0
	if hurt_anim:
		set_state(State.HURT)
		
func is_hurtable() -> bool:
	match state:
		State.LEVEL_INTRO, State.HURT, State.DEAD:
			return false
	return true
		
func use_power(amount: int) -> bool:
	if get_power_bar().target_value < amount:
		return false
	get_power_bar().target_value -= amount
	return true
	
func get_sfx(sfx_name: String) -> AudioStreamPlayer:
	return get_node("SFX/" + sfx_name)
	
func get_character_name() -> String:
	return CharacterNames[character]
