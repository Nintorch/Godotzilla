extends "res://Scripts/Screens/MainMenu/Menu.gd"

func menu_select(id: int) -> void:
	var menus: Array[Node2D] = [
		%VideoSettings,
		%SoundSettings,
		%Controls,
		%MenuMain,
	]
	
	main_menu.set_menu(menus[id])
