extends "res://Scripts/Screens/MainMenu/Menu.gd"

func menu_select(id: int) -> void:
	match id:
		0: # New Game
			main_menu.set_menu(%Saves)
		1: # Pass word game
			main_menu.change_scene(preload("res://Scenes/Screens/PassWordGame.tscn"))
		2: # Settings
			main_menu.set_menu(%Settings)
		3: # Credits
			main_menu.change_scene(preload("res://Scenes/Screens/Credits.tscn"))
		4: # Exit
			get_tree().paused = true
			
			Global.music_fade_out()
			Global.fade_out()
			await Global.fade_end
			
			await get_tree().create_timer(0.25).timeout
			
			get_tree().quit()
