extends "res://Scripts/MainMenu/Menu.gd"

# Explanation of the save system:
# When the player gets on a board (using a save ofc)
# the board's id is saved in the save file.
# In this menu the needed BoardDescription is found by
# comparing the board ids
#
# After the player completes the board, the next board
# the player is sent to is determined by "next_board"
# exported variable.

@export var boards: Array[BoardDescription]
@export var starting_scene: PackedScene

@onready var delete_text: Label = $DeleteText
@onready var message_window: MessageWindow = $MessageWindow

var save_slots: Array[Control] = []
var delete_mode := false

func _ready() -> void:
	super._ready()
	delete_text.hide()
	save_slots.assign(get_children().filter(
		func(c: Control) -> bool: return c.is_in_group("saveslot")
		))
	
	var save_id := 0
	for save_slot in save_slots:
		SaveManager.set_save_slot(save_id)
		var save_data := SaveManager.load_save_data()
		var board_description := get_board_description(save_data)
		if board_description == null:
			save_slot.set_data_empty(save_id)
		else:
			save_slot.set_data(save_id, board_description, save_data)
		save_id += 1
		
	save_slots[0].select()
	
func menu_enter() -> void:
	main_menu.selector.hide()
		
func _process(_delta: float) -> void:
	save_slots.map(func(s: Control) -> void: s.deselect())
	if main_menu.selector_option < save_slots.size():
		main_menu.selector.hide()
		save_slots[main_menu.selector_option].select()
	else:
		main_menu.selector.show()

func menu_select(id: int) -> void:
	match id:
		3:
			delete_mode = not delete_mode
			delete_text.visible = delete_mode
		4:
			main_menu.set_menu(%MenuMain)
		_:
			SaveManager.set_save_slot(id)
			var save_data := SaveManager.load_save_data()
			var board_description := get_board_description(save_data)
			
			if delete_mode:
				if board_description == null:
					return
				main_menu.selector.set_process(false)
				
				var result := await message_window.appear(
					"Do you want to delete this slot?", true, true)
				if result:
					var save_file := SaveManager.load_save_file()
					save_file.erase_section(SaveManager.get_save_slot_section())
					SaveManager.store_save_file(save_file)
					save_slots[id].set_data_empty(id)
					delete_mode = false
					delete_text.hide()
					
				main_menu.selector.set_process(true)
			else:
				if board_description == null:
					main_menu.change_scene(starting_scene)
					return
				
				get_tree().paused = true
				
				Global.music_fade_out()
				await Global.fade_out()
				await get_tree().create_timer(0.5).timeout
				
				get_tree().paused = false
				Global.score = save_data.get("score", 0)
				Global.change_scene(board_description.scene)

func get_board_description(save_data: Dictionary) -> BoardDescription:
		var board_id: String = save_data.get("board_id", "")
		if board_id.is_empty():
			return null
		return boards.filter(
			func(b: BoardDescription) -> bool: return b.board_id == board_id
			)[0]
