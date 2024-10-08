extends "res://Scripts/Objects/Enemies/BaseEnemy.gd"

const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var velocity := Vector2()

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
		
	if velocity.y == 0.0 and global_position.x < \
		camera.get_screen_center_position().x + Global.get_content_size().x / 2 + 20:
			velocity = Vector2(-120, -90)
			animation_player.play("main")
	elif velocity.y == -90.0 and global_position.x < camera.get_screen_center_position().x + 60:
		velocity.y = -60.0

func _physics_process(delta: float) -> void:
	position += velocity * delta
	
func _on_health_component_dead() -> void:
	velocity.x = -velocity.x

func _on_attack_component_attacked(_body: Node2D, _amount: float) -> void:
	var explosion := EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()
