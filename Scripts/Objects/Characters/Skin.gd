class_name PlayerSkin
extends Node2D

@export var character_name := ""

@export_group("Character-specific stats")
@export var bar_count := 6
@export var move_state: PlayerCharacter.State
## Character move speed in pixels per frame (in case of 60 fps)
@export var move_speed := 1.0
@export var level_intro_x_start := -35
@export var level_intro_y_offset := 0

@export_group("Character-specific stats/For walking characters")
@export var walk_frame_speed := 9.0
@export var jump_speed := -2 * 60

@export_group("Character-specific SFX")
@export var step_sfx: AudioStream
@export var roar_sfx: AudioStream

@onready var player: PlayerCharacter

func _ready() -> void:
	if get_parent() is PlayerCharacter:
		player = get_parent()

func walk_process() -> void:
	pass

func common_ground_attacks() -> void:
	if player.inputs_pressed[PlayerCharacter.Inputs.A]:
		player.use_attack(PlayerCharacter.Attack.PUNCH)
	if player.animation_player.current_animation != "Crouch" \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]:
			player.use_attack(PlayerCharacter.Attack.KICK)
