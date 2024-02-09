class_name Capsule
extends Sprite2D

enum Type {
	HEALTH,
	POWER,
}

@onready var sfx: AudioStreamPlayer = $SFX
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var timer: Timer = $Timer

var type: Type
var velocity: float = 1.3 * 60
var direction := 1

func initialize(global_position: Vector2, type: Type) -> Capsule:
	self.global_position = global_position
	self.type = type
	
	var animation := ""
	match type:
		Type.HEALTH:	animation = "health"
		Type.POWER:		animation = "power"
	animation_player.play(animation)
	return self

func _process(delta: float) -> void:
	if direction > 0 \
	and (global_position.x + 4) > get_viewport().get_camera_2d().limit_right:
		direction = -1
		
	position.x += velocity * direction * delta

func _on_timer_timeout() -> void:
	velocity = 0.3 * 60
	for body in area_2d.get_overlapping_bodies():
		_on_area_2d_body_entered(body)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not timer.is_stopped():
		return
		
	if body is GameCharacter:
		destroy(body)
		
func destroy(character: GameCharacter) -> void:
	visible = false
	area_2d.queue_free()
	sfx.play()
	sfx.finished.connect(func():
		queue_free()
		)
		
	match type:
		Type.HEALTH:	character.health.heal(2 * 8)
		Type.POWER:		character.power.add(2 * 8)
