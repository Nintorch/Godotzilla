class_name Explosion
extends Sprite2D

# TODO: make this script-only object

var velocity: Vector2

func _init(new_global_position: Vector2) -> void:
	global_position = new_global_position

func _ready() -> void:
	texture = preload("res://Sprites/explosion.png")
	hframes = 2
	vframes = 1
	
	# From -2 to 2
	velocity = Vector2(-2 + randi() % 5, -2 + randi() % 5) * 60

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 4:
		if frame == 0:
			frame = 1
		else:
			queue_free()
	position += velocity * delta
