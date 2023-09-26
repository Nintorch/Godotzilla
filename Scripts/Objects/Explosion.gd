extends Sprite2D

var velocity: Vector2

func _ready() -> void:
	# From -2 to 2
	velocity = Vector2(-2 + randi() % 5, -2 + randi() % 5) * 60

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 4:
		if frame == 0:
			frame = 1
		else:
			queue_free()
	position += velocity * delta
