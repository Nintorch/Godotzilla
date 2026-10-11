extends "res://Scripts/Screens/MainMenu/Menu.gd"

@onready var vibration_text: Label = $Vibration

func _process(_delta: float) -> void:
	match main_menu.selector_option:
		3:
			if Input.is_action_just_pressed("Left") and Global.controller_vibration:
				vibration_text.text = "vibration: off"
				Global.controller_vibration = false
				
			if Input.is_action_just_pressed("Right") and not Global.controller_vibration:
				vibration_text.text = "vibration: on"
				Global.controller_vibration = true
				if 0 in Input.get_connected_joypads():
					Input.start_joy_vibration(0, 0.2, 0.2, 0.4)
					
func menu_enter() -> void:
	if Global.controller_vibration:
		vibration_text.text = "vibration: on"

func menu_select(id: int) -> void:
	if id == 3: return # Vibration
	var menus: Array[Node2D] = [
		%VideoSettings,
		%SoundSettings,
		%Controls,
		null,
		%MenuMain,
	]
	
	main_menu.set_menu(menus[id])

func menu_exit() -> void:
	var file := SaveManager.load_settings_file()
	file.set_value(ControlsSettings.SECTION, "vibration", Global.controller_vibration)
	SaveManager.save_settings_file(file)
