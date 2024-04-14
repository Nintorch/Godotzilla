extends "res://Scripts/Objects/Enemies/BaseEnemy.gd"

enum State {
	IDLE,
	MOVING_LEFT,
	MOVING_RIGHT,
}

const JET_PROJECTILE = preload("res://Objects/Levels/Enemies/JetProjectile.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state := State.IDLE
var velocity := Vector2()
var launched_projectile := false

func _ready() -> void:
	attack_component.set_collision(Vector2(20, 10), Vector2.ZERO)

func _process(delta: float) -> void:
	match state:
		State.IDLE:
			if position.x < \
			get_viewport().get_camera_2d().position.x + Global.get_content_size().x / 2 + 30:
				state = State.MOVING_LEFT
				velocity = Vector2(-0.8 * 60, -0.2 * 60)
				animation_player.play("flying_left")
				
		State.MOVING_LEFT:
			velocity.x -= 0.1 * 60 * 60 * delta
			
			if Global.player.character == GameCharacter.Type.MOTHRA \
			and position.x < Global.player.position.x + 150:
				state = State.MOVING_RIGHT
				animation_player.play("flying_right")
				
		State.MOVING_RIGHT:
			velocity.x += 0.05 * 60 * 60 * delta
			if not launched_projectile and absf(velocity.x) < 0.04 * 60:
				var projectile := JET_PROJECTILE.instantiate()
				projectile.position = position
				get_parent().add_child(projectile)
				projectile.attack_component.objects_to_ignore.append(self)
				launched_projectile = true
		
	position += velocity * delta

func _on_attack_component_attacked(_body: Node2D, _amount: float) -> void:
	_on_health_component_dead()
	
func _on_health_component_damaged(_amount: float, _hurt_time: float) -> void:
	pass
	
func _on_health_component_dead() -> void:
	destroy_sfx.play()
	destroy_sfx.reparent(get_parent())
	get_parent().add_child(Explosion.new(global_position))
	queue_free()
