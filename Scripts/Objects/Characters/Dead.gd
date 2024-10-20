extends "res://Scripts/Objects/Characters/PlayerState.gd"

const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

func state_entered() -> void:
	player.collision_mask = 0
	player.velocity = Vector2(0, 0.3 * 60)
	player.animation_player.play("Hurt", -1, 0)
	if player.is_flying():
		player.get_node("MothraFloorChecking").collision_mask = 0
	
func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 0:
		var explosion := EXPLOSION.instantiate()
		explosion.global_position = player.global_position
		add_child(explosion)
		Global.play_global_sfx("Explosion")
