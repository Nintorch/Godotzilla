extends Level

func next_level() -> void:
	data.board_piece.remove()
	
	if Global.board.get_player_pieces().size() == 0:
		get_tree().paused = true
		
		Global.music_fade_out()
		await Global.fade_out()
		
		await get_tree().create_timer(0.5).timeout
		
		get_tree().paused = false
		save_data()
		Global.change_scene(Global.board.next_scene)
		
	else:
		
		if Global.board.music != music:
			Global.music_fade_out()
		await Global.fade_out(true)
		
		Global.change_scene_node(Global.board)
		Global.board.returned()

func save_data() -> void:
	if Global.board.use_in_saves:
		Global.save_data.board_data = Global.board.board_data
		Global.save_data.score = Global.score
		Global.store_save_data()
