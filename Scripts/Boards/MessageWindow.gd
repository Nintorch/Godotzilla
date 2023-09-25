extends NinePatchRect

@export var window_size = Vector2i(96, 72)
@export var alignment_horizontal = HORIZONTAL_ALIGNMENT_LEFT
@export var alignment_vertical = VERTICAL_ALIGNMENT_TOP
@onready var text: Label = $Text
var default_window_size = Vector2i(window_size)

enum State {
	HIDDEN,
	SHOWN,
	APPEARING,
	DISAPPEARING,
}

var state = State.HIDDEN
var timer = 0.0
var next_text = ""

func _ready():
	size.y = window_size.y
	visible = false
	text.visible = false
	text.horizontal_alignment = alignment_horizontal
	text.vertical_alignment = alignment_vertical

func _process(delta: float):
	if state == State.APPEARING:
		timer += delta
		if timer * 60 > 1:
			timer -= 1.0 / 60
			if visible:
				size.x += 16
			else:
				visible = true
			
			if size.x >= window_size.x:
				state = State.SHOWN
				text.visible = true
				timer = 0
				
	elif state == State.DISAPPEARING:
		timer += delta
		if timer * 60 > 1:
			timer -= 1.0 / 60
			if size.x > 16:
				size.x -= 16
			elif next_text:
				text.text = next_text
				text.size.x = window_size.x - 8
				text.size.y = window_size.y - 16
				next_text = ""
				state = State.APPEARING
				timer = 0
			else:
				visible = false
				state = State.HIDDEN
				timer = 0
	
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
		
	self.text.text = message
	self.text.visible = false
	self.text.size.x = window_size.x - 8
	self.text.size.y = window_size.y - 16
	
	visible = false
	state = State.APPEARING
	
	if enable_sound:
		$MenuBip.play()
	
func disappear():
	if state == State.SHOWN:
		text.visible = false
		state = State.DISAPPEARING
		
func get_text() -> String:
	return $Text.text
