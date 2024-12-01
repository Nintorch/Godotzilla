class_name GameCharacter
extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent
@onready var power: PowerComponent = $PowerComponent

func get_character_name() -> String:
	return "Game Character"

func is_hurtable() -> bool:
	return true
