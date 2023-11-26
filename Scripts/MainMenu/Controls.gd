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
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			exit()
			return
			
		if not event.is_echo() and event.is_pressed():
			process_input(event)
	elif event is InputEventJoypadMotion and current_input < 4:
		if abs(event.axis_value) > 0.5:
			current_input = 0
			var inputs = [
				[JOY_AXIS_LEFT_Y, -0.5],
				[JOY_AXIS_LEFT_Y, 0.5],
				[JOY_AXIS_LEFT_X, -0.5],
				[JOY_AXIS_LEFT_X, 0.5],
			]
			for i in inputs:
				var input = InputEventJoypadMotion.new()
				input.axis = i[0]
				input.axis_value = i[1]
				process_input(input)
	elif event is InputEventJoypadButton and event.pressed:
		process_input(event)
			
func update_text() -> void:
	current_button.text = "press button " + ACTIONS[current_input]
	
func next_input() -> void:
	current_input += 1
	if current_input >= ACTIONS.size():
		save_mapping()
		var file = Global.load_settings_file()
		load_mapping(file)
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
	var has_joypads: bool = Input.get_connected_joypads().size() > 0
	for action in ACTIONS:
		var input = file.get_value("Input", action)
		if input is InputEventJoypadMotion or input is InputEventJoypadButton \
			and has_joypads:
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, input)
