extends "res://Scripts/Screens/MainMenu/Menu.gd"

func menu_select(id: int) -> void:
	match id:
		0: # Continue
			PauseManager.finish_pause()
		1: # Settings
			main_menu.set_menu(%Settings)
		2: # Exit
			PauseManager.prepare_for_exit()
			get_tree().paused = true
			
			Global.music_fade_out()
			Global.fade_out()
			await Global.fade_end
			main_menu.hide()
			
			await get_tree().create_timer(0.25).timeout
			
			get_tree().paused = false
			Global.change_scene(preload("res://Scenes/Screens/MainMenu/MainMenu.tscn"))
			main_menu.queue_free()
