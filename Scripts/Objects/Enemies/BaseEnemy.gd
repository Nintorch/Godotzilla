class_name Enemy
extends StaticBody2D

@onready var health_component := $HealthComponent
@onready var attack_component := $AttackComponent

func _on_health_component_damaged(_amount: float, _hurt_time: float) -> void:
	# print("Oh no, I was damaged!!11 Nooo1oo!O")
	pass

func _on_health_component_dead() -> void:
	# print("I'm dead :((((")
	queue_free()

func start_destroy_sfx() -> void:
	Global.play_sfx_globally(preload("res://Audio/SFX/CharHurt.wav"))
