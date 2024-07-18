extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var velocity: Vector2

func _ready() -> void:
	animation_player.play("animation")
	# From -2 to 2
	velocity = Vector2(-2 + randi() % 5, -2 + randi() % 5) * 60

func _physics_process(delta: float) -> void:
	position += velocity * delta
