extends TextureRect

@export var custom_size := false
@export var width_before_0 := 50

func _ready() -> void:
	if not custom_size:
		var width: float = get_parent().get_node("Camera").limit_right + width_before_0
		size.x = width
	var collision_shape := $StaticBody2D/CollisionShape2D
	collision_shape.shape = collision_shape.shape.duplicate()
	collision_shape.shape.size.x = size.x + width_before_0
	collision_shape.position.x = size.x / 2 - width_before_0 / 2
