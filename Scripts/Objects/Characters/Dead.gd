extends State

const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

func state_entered() -> void:
	parent.collision_mask = 0
	parent.velocity = Vector2(0, 0.3 * 60)
	parent.animation_player.play("Hurt", -1, 0)
	if parent.is_flying():
		parent.get_node("MothraFloorChecking").collision_mask = 0
	
func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 0:
		var explosion := EXPLOSION.instantiate()
		explosion.global_position = parent.global_position
		add_child(explosion)
		Global.play_sfx_globally(preload("res://Audio/SFX/CharHurt.wav"))
