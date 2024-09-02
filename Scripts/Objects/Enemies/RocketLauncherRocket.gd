extends Node2D

const LAUNCH_HEIGHT := 30
const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

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
	
	var camera := get_viewport().get_camera_2d()
	var limit := Global.get_content_size().y + 64
	if camera != null:
		limit += camera.get_screen_center_position().y
	if position.y > limit:
		queue_free()

func _on_attack_component_attacked(_body: Node2D, _amount: float) -> void:
	var explosion := EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	destroy_sfx.play()
	destroy_sfx.reparent(get_parent())
	destroy_sfx.finished.connect(func() -> void: destroy_sfx.queue_free())
	queue_free()
