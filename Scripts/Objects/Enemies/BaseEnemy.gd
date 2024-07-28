class_name Enemy
extends StaticBody2D

@onready var health_component = $HealthComponent
@onready var attack_component = $AttackComponent
@onready var destroy_sfx: AudioStreamPlayer = $DestroySFX

func _on_health_component_damaged(_amount: float, _hurt_time: float) -> void:
	print("Oh no, I was damaged!!11 Nooo1oo!O")

func _on_health_component_dead() -> void:
	print("I'm dead :((((")
	queue_free()

func start_destroy_sfx() -> void:
	destroy_sfx.finished.connect(func():
		destroy_sfx.queue_free()
		)
	destroy_sfx.play()
	destroy_sfx.reparent(Global.get_current_scene())
