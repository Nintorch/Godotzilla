extends AudioStreamPlayer

func _process(_delta: float) -> void:
	if not Global.fading and Input.is_action_just_pressed("Select"):
		get_tree().paused = not get_tree().paused
		play()
		
		if not get_tree().paused:
			await finished
		Global.music.stream_paused = get_tree().paused
