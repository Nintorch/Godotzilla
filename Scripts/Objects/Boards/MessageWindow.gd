class_name MessageWindow extends NinePatchRect

enum State {
	HIDDEN,
	SHOWN,
	APPEARING,
	DISAPPEARING,
}

## Player's response to Yes/No choice message.
## CANCEL is returned when the player presses action B, i.e. cancels their action.
## UNKNOWN is returned by make_choice() if the choice message cannot be displayed
## (the message window object is either appearing or disappearing at the moment).
enum Response {
	YES,
	NO,
	CANCEL,
	UNKNOWN,
}

@export var selector: BoardSelector
@export var window_size := Vector2i(96, 64)
@export var alignment_horizontal := HORIZONTAL_ALIGNMENT_LEFT
@export var alignment_vertical := VERTICAL_ALIGNMENT_TOP

@onready var text: Label = $Text
@onready var choice_nodes: Node2D = $Choice
@onready var choice_selector: Sprite2D = $Choice/Selector

var default_window_size := Vector2i(window_size)
var state := State.HIDDEN

## The player made a choice after being presented with a Yes/No choice
signal choice_made(choice: Response)

func _ready() -> void:
	size = Vector2(0, window_size.y)
	visible = false
	text.visible = false
	choice_nodes.visible = false
	text.horizontal_alignment = alignment_horizontal
	text.vertical_alignment = alignment_vertical
	
func _process(_delta: float) -> void:
	if choice_nodes.visible:
		if Input.is_action_just_pressed("Left"):
			choice_selector.position.x = 0
		if Input.is_action_just_pressed("Right"):
			choice_selector.position.x = 40
			
		var input_a := Input.is_action_just_pressed("A")
		if input_a or Input.is_action_just_pressed("B"):
			Global.play_global_sfx("MenuBip")
			await disappear()
				
			if input_a:
				choice_made.emit(
					Response.YES if choice_selector.position.x == 0 else Response.NO
					)
			else:
				choice_made.emit(Response.CANCEL)
					
			choice_selector.position.x = 0
			if selector:
				selector.ignore_player_input = false

func appear(
		message: String,
		enable_sound := true,
		req_size: Vector2i = default_window_size,
		) -> void:
	if state == State.APPEARING or state == State.DISAPPEARING:
		return
		
	window_size = req_size
	
	if state == State.SHOWN:
		await disappear()
	
	size = Vector2(0, window_size.y)
		
	self.text.text = message
	self.text.visible = false
	self.text.size.x = window_size.x
	self.text.size.y = window_size.y - 16
	
	visible = true
	state = State.APPEARING
	size.x = 0
	
	var tween := create_tween()
	tween.tween_property(self, "size:x", req_size.x, get_tween_seconds(req_size.x))

	if enable_sound and not (is_instance_valid(selector) and selector.ignore_player_input):
		Global.play_global_sfx("MenuBip")
		
	await tween.finished
	text.visible = true
	state = State.SHOWN
	
## Make the message window appear and ask the player to make a Yes/No choice
func make_choice(message: String, enable_sound := true, req_size := default_window_size) -> Response:
	if state == State.APPEARING or state == State.DISAPPEARING:
		return Response.UNKNOWN
		
	await appear(message, enable_sound, req_size)
	
	choice_nodes.show()
	choice_nodes.position.y = default_window_size.y - 16
	if selector:
		selector.ignore_player_input = true

	return await choice_made
	
## Disappear slowly
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
		
## Disappear immediately
func make_hide() -> void:
	visible = false
	text.visible = false
	choice_nodes.visible = false
	state = State.HIDDEN
	size = Vector2(0, window_size.y)
		
## Get the currently shown text
func get_text() -> String:
	return $Text.text

func get_tween_seconds(pixel_width: float) -> float:
	return pixel_width / 16 / 60
