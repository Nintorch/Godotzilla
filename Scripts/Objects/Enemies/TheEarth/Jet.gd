extends "res://Scripts/Objects/Enemies/BaseEnemy.gd"

enum {
	IDLE,
	MOVING_LEFT,
	MOVING_RIGHT,
}

const JET_PROJECTILE = preload("res://Objects/Levels/TestLevel/Enemies/JetProjectile.tscn")
const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state := IDLE
var velocity := Vector2()
var launched_projectile := false

func _process(delta: float) -> void:
	match state:
		IDLE:
			var camera := get_viewport().get_camera_2d()
			if camera != null \
				and position.x < camera.position.x + Global.get_content_size().x / 2 + 30:
					state = MOVING_LEFT
					velocity = Vector2(-0.8 * 60, -0.2 * 60)
					animation_player.play("flying_left")
				
		MOVING_LEFT:
			velocity.x -= 0.1 * 60 * 60 * delta
			
			if Global.player != null and Global.player.character == PlayerCharacter.Type.MOTHRA \
				and position.x < Global.player.position.x + 150:
					state = MOVING_RIGHT
					animation_player.play("flying_right")
				
		MOVING_RIGHT:
			velocity.x += 0.05 * 60 * 60 * delta
			if not launched_projectile and absf(velocity.x) < 0.04 * 60:
				var projectile := JET_PROJECTILE.instantiate()
				projectile.position = position
				add_sibling(projectile)
				projectile.attack_component.objects_to_ignore.append(self)
				launched_projectile = true
		
	position += velocity * delta

func _on_attack_component_attacked(_body: Node2D, _attack: AttackDescription) -> void:
	_on_health_component_dead()
	
func _on_health_component_damaged(_amount: float, _attack: AttackDescription) -> void:
	pass
	
func _on_health_component_dead() -> void:
	var explosion := EXPLOSION.instantiate()
	explosion.global_position = global_position
	
	start_destroy_sfx()
	add_sibling(explosion)
	queue_free()
