extends Level

func next_level() -> void:
	Global.music_fade_out()
		
	get_tree().paused = true
	
	Global.fade_out()
	await Global.fade_end
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	
	Global.change_scene(Global.board.next_board)
