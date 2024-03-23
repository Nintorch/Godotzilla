extends Node2D

const JETS_SPEED := 0.25 * 60
@onready var jets: TextureRect = $Jets

func _process(delta: float) -> void:
	jets.position.x += JETS_SPEED * delta
