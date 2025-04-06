class_name PlayerSkin extends Node2D

@export var character_info: CharacterInfo

@export_group("Gameplay-specific stats")
@export var move_state: PlayerCharacter.State
## Character move speed in pixels per frame (in case of 60 fps)
@export var move_speed := 1.0

@export_group("Gameplay-specific stats/For walking characters", "walking_")
@export var walking_walk_animation_speed := 9.0
@export var walking_jump_speed := -2 * 60

@export_group("Gameplay-specific stats/For flying characters", "flying_")
@export var flying_top_y_limit := 72
## When the camera is following the player when they're moving right,
## in this case this move speed for horizontal axis is used and
## not the regular move speed
@export var flying_move_speed_2 := 1.0
@export var flying_floor_check_y_offset := 12.0

@export_group("Gameplay-specific stats/Level Intro", "intro_")
@export var intro_start_x := -35
## The X position of the character when the level intro should stop
@export var intro_target_x := 64
## The offset from the default character position in a level on the vertical axis.
## Used by Mothra to make her start in the air 
@export var intro_y_offset := 0
## The number of physics frames between 2 step sounds
@export var intro_step_sfx_period := 30
## When the step sound effects should start (in physics frames)
@export var intro_step_sfx_start := 15
## The offset of when the steps sfx should play (in physics frames)
@export var intro_step_sfx_offset := 10
		
@export_group("Attacks")
@export var attack_animation_player: AnimationPlayer
@export var attack_function_callback_node: Node
## The Advanced function callbacks will be called on this skin object
@export var attacks: Array[AttackDescription]

@onready var attack_hitboxes: Node2D = $Hitboxes

var player: PlayerCharacter
var attack_state_node: StateMachineState
var move_state_node: StateMachineState

func _ready() -> void:
	if get_parent() is PlayerCharacter:
		player = get_parent()
		attack_state_node = player.state.states_list[PlayerCharacter.State.ATTACK]
		move_state_node = player.state.states_list[move_state]
	
	attack_hitboxes.hide()
	$Collision.hide()

func walk_process() -> void:
	pass

func common_ground_attacks() -> void:
	if player.inputs_pressed[PlayerCharacter.Inputs.A]:
		player.attack.start_attack("Punch")
	if player.animation_player.current_animation != "Crouch" \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]:
			player.attack.start_attack("Kick")
