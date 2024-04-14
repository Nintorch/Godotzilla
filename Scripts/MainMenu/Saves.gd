extends "res://Scripts/MainMenu/Menu.gd"

# Explanation of the save system:
# When the player gets on a board (using a save ofc)
# the board's name is saved in the save file.
# In this menu the needed BoardDescription is found by
# comparing the board names
#
# After the player completes the board, the next board
# the player is sent to is determined by "next_board"
# exported variable.

@export var boards: Array[BoardDescription]
@export var starting_scene: PackedScene

func menu_select(id: int) -> void:
	if id == 3:
		main_menu.set_menu(%MenuMain)
	else:
		Global.set_save_slot(id)
		
		var savefile := Global.load_save_file()
		var board_id: String = savefile.get_value(Global.get_save_slot_section(), "board", "")
		if board_id.is_empty():
			main_menu.change_scene(starting_scene)
			return
		var board_description: BoardDescription = boards.filter(
			func(b: BoardDescription): return b.board_id == board_id
			)[0]
		var scene := board_description.scene.instantiate()
		scene.board_data = savefile.get_value(Global.get_save_slot_section(), "board_data", {})
		
		get_tree().paused = true
		
		Global.fade_out()
		Global.music_fade_out()
		await Global.fade_end
		await get_tree().create_timer(0.5).timeout
		
		get_tree().paused = false
		Global.change_scene_node(scene)
