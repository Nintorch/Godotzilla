extends AnimatedSprite2D

enum Type {
	EYE_BEAM,
	WING,
}

@onready var timer = $Timer
@onready var animation_player = $AnimationPlayer

var velocity := Vector2()
var type: Type
var player: GameCharacter

func setup(type: Type):
	self.type = type
	match type:
		Type.EYE_BEAM:
			animation = "EyeBeam"
			timer.start(0.3)
			timer.timeout.connect(func(): queue_free())
			velocity = Vector2(5 * player.scale.x * 60, 0)
			
		Type.WING:
			animation = "Wing"
			animation_player.play("Flash")
			timer.start(0.4)
			timer.timeout.connect(func():
				animation_player.stop()
				visible = true # Just in case
				)
			velocity = Vector2(randi_range(2, 10) * 0.1 * 60,
							randi_range(6, 9) * 0.1 * 60)

func _physics_process(delta):
	if type == Type.WING:
		velocity.y += 1 * 60 * delta
	position += velocity * delta
	
	if position.y > \
		get_viewport().get_camera_2d().get_screen_center_position().y \
		+ Global.get_content_size().y / 2 + 20:
		queue_free()
