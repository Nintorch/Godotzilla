extends AnimatedSprite2D

@onready var timer = $Timer
@onready var animation_player = $AnimationPlayer

var velocity := Vector2()
var type := ""
var player: GameCharacter

enum Type {
	EYE_BEAM,
	WING,
}

func setup(type: Type):
	match type:
		Type.EYE_BEAM:
			animation = "EyeBeam"
			timer.start(0.3)
			timer.timeout.connect(func(): queue_free())
			velocity = Vector2(5 * player.scale.x * 60, 0)
		Type.WING:
			animation = "Wing"
			animation_player.play("Flash")
			velocity = Vector2(randi_range(1, 6) * 0.1 * 60,
							randi_range(4, 6) * 0.1 * 60)

func _physics_process(delta):
	position += velocity * delta
	
	if position.y > \
		get_viewport().get_camera_2d().get_screen_center_position().y \
		+ Global.get_content_size().y / 2 + 20:
		queue_free()
