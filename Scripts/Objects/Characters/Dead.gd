extends "res://Scripts/Objects/Characters/State.gd"

const Explosion = preload("res://Objects/Explosion.tscn")

func state_entered() -> void:
	Global.play_music(preload("res://Audio/Soundtrack/PlayerDeath.ogg"))
	parent.collision_mask = 0
	parent.velocity = Vector2(0, 0.3 * 60)
	parent.animation_player.play("Hurt", -1, 0)
	await Global.music.finished
	
	get_tree().paused = true
	Global.fade_out()
	await Global.fade_end
	get_tree().paused = false
	
	# TODO: if there are other playable characters left on the board,
	# go back to the board and remove the current character piece.
	Global.change_scene(preload("res://Scenes/GameOver.tscn"))
	
func _process(delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 0:
		var explosion = Explosion.instantiate()
		explosion.global_position = parent.global_position
		add_child(explosion)
