extends Node2D

const VELOCITY := Vector2(-1 * 60, 0.5 * 60)

@onready var destroy_sfx: AudioStreamPlayer = $DestroySFX
@onready var attack_component: AttackComponent = $AttackComponent

func _process(delta: float) -> void:
	position += VELOCITY * delta

func _on_attack_component_attacked(_body: Node2D, _attack: AttackDescription) -> void:
	Global.create_explosion(global_position)
	queue_free()
