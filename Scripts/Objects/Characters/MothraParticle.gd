extends AnimatedSprite2D

enum Type {
	EYE_BEAM,
	WING,
}

@onready var timer = $Timer
@onready var animation_player = $AnimationPlayer
@onready var attack_component: Node2D = $AttackComponent

var velocity := Vector2()
var type: Type

func setup(init_type: Type, player: GameCharacter):
	type = init_type
	attack_component.objects_to_ignore.append(player)
	
	var should_destroy := false
	scale.x = player.direction
	match type:
		Type.EYE_BEAM:
			animation = "EyeBeam"
			timer.start(0.3)
			timer.timeout.connect(func(): queue_free())
			velocity = Vector2(5 * player.direction * 60, 0)
			should_destroy = true
			
		Type.WING:
			animation = "Wing"
			animation_player.play("Flash")
			timer.start(0.4)
			timer.timeout.connect(func():
				animation_player.stop()
				visible = true # Just in case
				)
			velocity = Vector2(randi_range(2, 10) * 0.1 * 60 * player.direction,
							randi_range(6, 9) * 0.1 * 60)
							
	if should_destroy:
		attack_component.attacked.connect(func(_body: Node2D, _amount: float):
			queue_free()
			)
			
	attack_component.set_collision(
		sprite_frames.get_frame_texture(animation, 0).get_size(),
		Vector2.ZERO
		)

func _physics_process(delta):
	if type == Type.WING:
		velocity.y += 1 * 60 * delta
	position += velocity * delta
	
	if position.y > \
		get_viewport().get_camera_2d().get_screen_center_position().y \
		+ Global.get_content_size().y / 2 + 20:
		queue_free()
