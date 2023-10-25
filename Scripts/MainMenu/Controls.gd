class_name ControlsSettings
extends "res://Scripts/MainMenu/Menu.gd"

const ACTIONS = [
	"Up", "Down", "Left", "Right",
	"B", "A", "Select", "Start"
]
const SECTION = "Input"

@onready var current_button: Label = $CurrentButton
var current_input := 0
var mapping: Array[InputEvent] = []

func menu_enter() -> void:
	current_input = 0
	update_text()
	
	mapping.resize(ACTIONS.size())
	mapping.fill(null)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		exit()
		return
		
	if event is InputEventKey \
		and not event.is_echo() and event.is_pressed():
		process_input(event)
			
func update_text() -> void:
	current_button.text = "press button " + ACTIONS[current_input]
	
func next_input() -> void:
	current_input += 1
	if current_input >= ACTIONS.size():
		save_mapping()
		Global.load_input_mapping()
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
	main_menu.set_menu($"../Settings")

func save_mapping() -> void:
	var file = Global.load_settings_file()
	for i in ACTIONS.size():
		file.set_value(SECTION, ACTIONS[i], mapping[i])
	Global.save_settings_file(file)
	
static func load_mapping(file: ConfigFile) -> void:
	if not file.has_section("Input"):
		return
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, file.get_value("Input", action))