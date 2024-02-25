extends Node2D

const LAUNCH_HEIGHT := 30

@onready var attack_component: Node2D = $AttackComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var destroy_sfx: AudioStreamPlayer = $DestroySFX

var velocity := Vector2(-0.5 * 60, -4 * 60)
var initial_position := Vector2()

func _ready() -> void:
	initial_position = Vector2(position)

func _process(delta: float) -> void:
	if position.y < initial_position.y - LAUNCH_HEIGHT:
		if animation_player.current_animation != "going_down":
			animation_player.play("going_down")
		velocity.x -= 0.01 * 60 * 60 * delta
		velocity.y += 0.1 * 60 * 60 * delta
	position += velocity * delta
	
	if position.y > get_viewport().get_camera_2d().limit_bottom:
		queue_free()

func _on_attack_component_attacked(body: Node2D, amount: float) -> void:
	get_parent().add_child(Explosion.new(global_position))
	destroy_sfx.play()
	destroy_sfx.reparent(get_parent())
	queue_free()
