extends Node2D

const VELOCITY := Vector2(-1 * 60, 0.5 * 60)
@onready var destroy_sfx: AudioStreamPlayer = $DestroySFX
@onready var attack_component: Node2D = $AttackComponent

func _process(delta: float) -> void:
	position += VELOCITY * delta

func _on_attack_component_attacked(body: Node2D, amount: float) -> void:
	destroy_sfx.play()
	destroy_sfx.reparent(get_parent())
	get_parent().add_child(Explosion.new(global_position))
	queue_free()
