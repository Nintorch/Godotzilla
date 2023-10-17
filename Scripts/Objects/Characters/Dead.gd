extends "res://Scripts/Objects/Characters/State.gd"

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
	
	if Global.board:
		Global.board.board_pieces.erase(Global.board.selected_piece)
		Global.board.selected_piece.remove()
		Global.board.selected_piece = null
		
		if Global.board.get_player_pieces().size() == 0:
			Global.change_scene(preload("res://Scenes/GameOver.tscn"))
		else:
			Global.change_scene_node(Global.board)
			Global.board.returned()
	else:
		Global.change_scene(preload("res://Scenes/GameOver.tscn"))
	
func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 0:
		var explosion = Explosion.new()
		explosion.global_position = parent.global_position
		add_child(explosion)
