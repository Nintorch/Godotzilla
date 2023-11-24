extends NinePatchRect

@export var window_size = Vector2i(96, 64)
@export var alignment_horizontal = HORIZONTAL_ALIGNMENT_LEFT
@export var alignment_vertical = VERTICAL_ALIGNMENT_TOP
@onready var text: Label = $Text

enum State {
	HIDDEN,
	SHOWN,
	APPEARING,
	DISAPPEARING,
}

var default_window_size = Vector2i(window_size)
var state = State.HIDDEN
var next_text = ""

func _ready():
	size = Vector2(0, window_size.y)
	visible = false
	text.visible = false
	text.horizontal_alignment = alignment_horizontal
	text.vertical_alignment = alignment_vertical

func _physics_process(delta: float) -> void:
	if state == State.APPEARING:
		if visible:
			size.x += 16
		else:
			visible = true
			
		if size.x >= window_size.x:
			state = State.SHOWN
			text.visible = true
				
	elif state == State.DISAPPEARING:
		if size.x > 16:
			size.x -= 16
		elif next_text:
			text.text = next_text
			text.size.x = window_size.x - 8
			text.size.y = window_size.y - 16
			next_text = ""
			state = State.APPEARING
		else:
			make_hide()
	
# TODO: check req_size
func appear(message: String, enable_sound = true, req_size: Vector2i = default_window_size):
	window_size = req_size
	
	if state == State.SHOWN:
		next_text = message
		disappear()
		if enable_sound:
			$MenuBip.play()
		return
	elif state == State.APPEARING or state == State.DISAPPEARING:
		return
	else:
		size = Vector2(0, window_size.y)
		
	self.text.text = message
	self.text.visible = false
	self.text.size.x = window_size.x - 8
	self.text.size.y = window_size.y - 16
	
	visible = false
	state = State.APPEARING
	
	if enable_sound:
		$MenuBip.play()
	
func disappear() -> void:
	if state == State.SHOWN:
		text.visible = false
		state = State.DISAPPEARING
		
func make_hide() -> void:
	visible = false
	state = State.HIDDEN
	size = Vector2(0, window_size.y)
		
func get_text() -> String:
	return $Text.text
