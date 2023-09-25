extends CharacterBody2D
class_name GameCharacter

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
	WALK,
	LEVEL_INTRO,
	ATTACK,
}

enum Attack {
	NONE,
	
	PUNCH,
	KICK,
	
	# Godzilla attacks
	HEAT_BEAM,
	TAIL_WHIP,
}

@onready var states_list: Array[Node] = $States.get_children()
var state = State.LEVEL_INTRO

var character = GameCharacter.Type.GODZILLA
var move_speed = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var hp = 6 * 8 # 6 bars
var level = 1
var direction = 1

var body: AnimatedSprite2D
var animation_player: AnimationPlayer

enum Inputs {
	XINPUT, YINPUT, B, A, START, SELECT,
	COUNT,
}

var inputs := []
var inputs_pressed := []
var has_input := true
const INPUT_ACTIONS = [["Left", "Right"], ["Up", "Down"], "B", "A", "Start", "Select"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_input:
		Global.player = self
	
	for i in Inputs.COUNT:
		inputs.append(0)
		inputs_pressed.append(0)
	
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
	
	move_speed = 1 * 60
	
	if position.x == 0:
		position.x = -40
		
	for i in states_list:
		var enable = i == states_list[state]
		i.set_process(enable)
		i.set_physics_process(enable)
		i.set_process_input(enable)
		
		i.state_init()
		if enable:
			i.state_entered()
		
func _physics_process(delta: float) -> void:
	if state != State.LEVEL_INTRO \
		and position.x <= Global.camera.limit_left + 16 and velocity.x < 0:
		position.x = Global.camera.limit_left + 16
		velocity.x = 0
				
	if not is_on_floor():
		velocity.y += gravity * delta
				
	move_and_slide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	process_input()
	get_life_bar().target_value = hp
	Global.level.get_HUD().set_player_level(level)
	
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
	
func get_sfx(name: String) -> AudioStreamPlayer:
	return get_node("SFX/" + name)
	
func get_character_name() -> String:
	return CharacterNames[character]
