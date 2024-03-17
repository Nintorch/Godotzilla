extends NinePatchRect

@export var selector: Node2D
@export var window_size = Vector2i(96, 64)
@export var alignment_horizontal = HORIZONTAL_ALIGNMENT_LEFT
@export var alignment_vertical = VERTICAL_ALIGNMENT_TOP
@onready var menu_bip: AudioStreamPlayer = $MenuBip

@onready var text: Label = $Text
@onready var choice_nodes: Node2D = $Choice
@onready var choice_selector: Sprite2D = $Choice/Selector

enum State {
	HIDDEN,
	SHOWN,
	APPEARING,
	DISAPPEARING,
}

var default_window_size = Vector2i(window_size)
var state = State.HIDDEN

signal choice_made(choice: bool)

func _ready() -> void:
	size = Vector2(0, window_size.y)
	visible = false
	text.visible = false
	choice_nodes.visible = false
	text.horizontal_alignment = alignment_horizontal
	text.vertical_alignment = alignment_vertical
	
func _process(delta: float) -> void:
	if choice_nodes.visible:
		if Input.is_action_just_pressed("Left"):
			choice_selector.position.x = 0
		if Input.is_action_just_pressed("Right"):
			choice_selector.position.x = 40
		var input_a := Input.is_action_just_pressed("A")
		if input_a or Input.is_action_just_pressed("B"):
			menu_bip.play()
			await disappear()
			choice_made.emit((choice_selector.position.x == 0)
				if input_a else false)
			selector.ignore_player_input = false
			choice_selector.position.x = 0
	
func appear(message: String, enable_sound := true, choice := false, req_size: Vector2i = default_window_size):
	if state == State.APPEARING or state == State.DISAPPEARING:
		return false
	
	window_size = req_size
	
	if state == State.SHOWN:
		await disappear()
	
	size = Vector2(0, window_size.y)
		
	self.text.text = message
	self.text.visible = false
	self.text.size.x = window_size.x - 8
	self.text.size.y = window_size.y - 16
	
	visible = true
	state = State.APPEARING
	size.x = 0
	
	var tween := create_tween()
	tween.tween_property(self, "size:x", req_size.x, get_tween_seconds(req_size.x))
	tween.finished.connect(func():
		text.visible = true
		if choice:
			choice_nodes.position.y = req_size.y - 16
			choice_nodes.visible = true
			selector.ignore_player_input = true
		state = State.SHOWN
		)
	
	if enable_sound:
		menu_bip.play()
		
	await tween.finished
	
	if choice:
		var ret: bool = await choice_made
		return ret
	return false
	
func disappear() -> void:
	if state != State.SHOWN:
		return
	
	text.visible = false
	choice_nodes.visible = false
	state = State.DISAPPEARING
	
	var tween := create_tween()
	tween.tween_property(self, "size:x", 0.0, get_tween_seconds(size.x))
	tween.finished.connect(make_hide)
	await tween.finished
		
func make_hide() -> void:
	visible = false
	text.visible = false
	choice_nodes.visible = false
	state = State.HIDDEN
	size = Vector2(0, window_size.y)
		
func get_text() -> String:
	return $Text.text

func get_tween_seconds(pixel_width: float) -> float:
	return pixel_width / 16 / 60
