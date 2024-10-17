class_name PlayerSkin
extends Node2D

@onready var player: PlayerCharacter = get_parent()

## Stuff for Walk.gd

var walk_frame_speed := 0

func walk_process() -> void:
	pass

func common_ground_attacks() -> void:
	if player.inputs_pressed[PlayerCharacter.Inputs.A]:
		player.use_attack(PlayerCharacter.Attack.PUNCH)
	if player.animation_player.current_animation != "Crouch" \
		and player.inputs_pressed[PlayerCharacter.Inputs.B]:
			player.use_attack(PlayerCharacter.Attack.KICK)
