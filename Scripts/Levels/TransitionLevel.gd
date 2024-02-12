extends Level

func next_level() -> void:
	player.board_piece.remove()
	
	if Global.board.get_player_pieces().size() == 0:
		get_tree().paused = true
		
		Global.music_fade_out()
		Global.fade_out()
		await Global.fade_end
		
		await get_tree().create_timer(0.5).timeout
		
		get_tree().paused = false
		Global.change_scene(Global.board.next_scene)
		
	else:
		get_tree().paused = true
		
		if Global.board.music != music:
			Global.music_fade_out()
		Global.fade_out()
		await Global.fade_end
		
		get_tree().paused = false
		
		Global.change_scene_node(Global.board)
		Global.board.returned()
