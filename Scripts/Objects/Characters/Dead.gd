extends "res://Scripts/Objects/Characters/State.gd"

func state_entered() -> void:
	parent.dead_state.emit()
	
	parent.collision_mask = 0
	parent.velocity = Vector2(0, 0.3 * 60)
	parent.animation_player.play("Hurt", -1, 0)
	if parent.is_flying():
		parent.get_node("MothraFloorChecking").collision_mask = 0
	await Global.music.finished
	
	get_tree().paused = true
	Global.fade_out()
	await Global.fade_end
	get_tree().paused = false
	
	if Global.board:
		if Global.board.selected_piece:
			Global.board.selected_piece.remove()
			Global.board.selected_piece = null
		
		if Global.board.get_player_pieces().size() == 0:
			Global.change_scene(preload("res://Scenes/GameOver.tscn"))
		else:
			Global.change_scene_node(Global.board)
			Global.board.returned(false if parent.is_player else true)
	else:
		Global.change_scene(preload("res://Scenes/GameOver.tscn"))
	
func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 0:
		Global.get_current_scene().add_child(Explosion.new(parent.global_position))
