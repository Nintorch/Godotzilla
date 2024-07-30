class_name ControlsSettings
extends "res://Scripts/MainMenu/Menu.gd"

const ACTIONS := [
	"Up", "Down", "Left", "Right",
	"B", "A", "Select", "Start"
]
const SECTION := "Input"

@onready var current_button: Label = $CurrentButton
@onready var reset_controls: Label = $ResetControls

var current_input := 0
var mapping: Array[InputEvent] = []

func menu_enter() -> void:
	reset_controls.text = reset_controls.text.replace("key",
		(InputMap.action_get_events("ResetControls")[0] as InputEventKey).as_text_physical_keycode())
	current_input = 0
	update_text()
	
	mapping.resize(ACTIONS.size())
	mapping.fill(null)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			exit()
			return
		process_input(event)
	elif (event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5) \
		or (event is InputEventJoypadButton and event.pressed):
			process_input(event)
			
func update_text() -> void:
	current_button.text = "press button " + ACTIONS[current_input]
	
func next_input() -> void:
	current_input += 1
	if current_input >= ACTIONS.size():
		save_mapping()
		var file := Global.load_settings_file()
		ControlsSettings.load_mapping(file)
		exit()
		return
	update_text()
		
func update_current_action(event: InputEvent) -> void:
	mapping[current_input] = event
	
func process_input(event: InputEvent) -> void:
	update_current_action(event)
	next_input()
	
func exit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	main_menu.set_menu(%Settings)

func save_mapping() -> void:
	var file = Global.load_settings_file()
	for i in ACTIONS.size():
		file.set_value(SECTION, ACTIONS[i], mapping[i])
	Global.save_settings_file(file)
	
static func load_mapping(file: ConfigFile) -> void:
	if not file.has_section("Input"):
		return
	var has_joypad: bool = Input.get_connected_joypads().size() > 0
	
	InputMap.load_from_project_settings()
	for action: String in ACTIONS:
		var input: InputEvent = file.get_value("Input", action)
		if not (input is InputEventKey) and not has_joypad:
			continue
		
		var events := InputMap.action_get_events(action).filter(func(x):
			return not (x is InputEventKey)
			)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, input)
		for old_event in events:
			InputMap.action_add_event(action, old_event)
