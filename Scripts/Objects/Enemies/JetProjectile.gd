extends Node2D

const VELOCITY := Vector2(-1 * 60, 0.5 * 60)
const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

@onready var destroy_sfx: AudioStreamPlayer = $DestroySFX
@onready var attack_component: Node2D = $AttackComponent

func _process(delta: float) -> void:
	position += VELOCITY * delta

func _on_attack_component_attacked(_body: Node2D, _amount: float) -> void:
	var explosion := EXPLOSION.instantiate()
	explosion.global_position = global_position
	
	destroy_sfx.play()
	destroy_sfx.reparent(get_parent())
	destroy_sfx.finished.connect(func() -> void: destroy_sfx.queue_free())
	get_parent().add_child(explosion)
	queue_free()
