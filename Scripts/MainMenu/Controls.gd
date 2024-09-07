class_name ControlsSettings
extends "res://Scripts/MainMenu/Menu.gd"

# Section in the save file
const SECTION := "Input"

const ACTIONS := [
	"Up", "Down", "Left", "Right",
	"B", "A", "Select", "Start"
]

# The controller image's regions that should be highlighted
# when the player is configuring their input mapping
const HIGHLIGHTS: Array[Rect2] = [
	Rect2(23, 44, 8, 8), # Up
	Rect2(23, 60, 8, 8), # Down
	Rect2(15, 52, 8, 8), # Left
	Rect2(31, 52, 8, 8), # Right
	Rect2(121, 55, 18, 18), # B
	Rect2(144, 55, 18, 18), # A
	Rect2(61, 61, 15, 6), # Select
	Rect2(88, 61, 15, 6), # Start
]

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
	
	var controller := $Controller
	var controller_position: Vector2 = controller.get_rect().position + controller.position
	var highlight := $ButtonHighlight
	highlight.region_rect = HIGHLIGHTS[current_input]
	highlight.position = controller_position + HIGHLIGHTS[current_input].position
	
func next_input() -> void:
	current_input += 1
	if current_input >= ACTIONS.size():
		save_mapping()
		load_mapping(Global.load_settings_file())
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
	var file := Global.load_settings_file()
	for i in ACTIONS.size():
		file.set_value(SECTION, ACTIONS[i], mapping[i])
	Global.save_settings_file(file)
	
static func init_controls() -> void:
	Input.joy_connection_changed.connect(func(_device: int, _connected: bool) -> void:
		load_mapping(Global.load_settings_file())
		)
	
static func load_mapping(file: ConfigFile) -> void:
	if not file.has_section("Input"):
		return
	var has_joypad: bool = Input.get_connected_joypads().size() > 0
	
	# Reset the input mapping
	InputMap.load_from_project_settings()
	
	for action: String in ACTIONS:
		var input: InputEvent = file.get_value("Input", action)
		if not (input is InputEventKey) and not has_joypad:
			continue
		
		# Get the default input events for this action that are not keys
		# so we can load them again below
		# For example, so we can have both a key and a gamepad stick movement
		# as the player's move input action
		var events := InputMap.action_get_events(action).filter(func(x: InputEvent) -> bool:
			return not (x is InputEventKey)
			)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, input)
		for old_event: InputEvent in events:
			InputMap.action_add_event(action, old_event)
