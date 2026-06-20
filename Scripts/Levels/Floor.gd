extends TextureRect

@export var width_before_0 := 50

func _ready() -> void:
	var width: float = get_parent().get_node("Camera").limit_right + width_before_0
	size.x = width
	var collision_shape := $StaticBody2D/CollisionShape2D
	collision_shape.shape.size.x = width + width_before_0 * 2
	collision_shape.position.x = width / 2 - width_before_0
