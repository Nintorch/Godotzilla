class_name GameCharacter
extends CharacterBody2D

## Using this is not required if you're using PlayerCharacter
@export var character_name: String = "Game character"

@onready var health: HealthComponent = $HealthComponent
@onready var power: PowerComponent = $PowerComponent

func get_character_name() -> String:
	return character_name

func is_hurtable() -> bool:
	return true
