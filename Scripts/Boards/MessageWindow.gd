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

func _ready():
	size = Vector2(0, window_size.y)
	visible = false
	text.visible = false
	text.horizontal_alignment = alignment_horizontal
	text.vertical_alignment = alignment_vertical
	
func appear(message: String, enable_sound := true, req_size: Vector2i = default_window_size):
	if state == State.APPEARING or state == State.DISAPPEARING:
		return
	
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
		state = State.SHOWN
		)
	
	if enable_sound:
		$MenuBip.play()
		
	await tween.finished
	
func disappear() -> void:
	if state != State.SHOWN:
		return
	
	text.visible = false
	state = State.DISAPPEARING
	
	var tween := create_tween()
	tween.tween_property(self, "size:x", 0.0, get_tween_seconds(size.x))
	tween.finished.connect(make_hide)
	await tween.finished
		
func make_hide() -> void:
	visible = false
	state = State.HIDDEN
	size = Vector2(0, window_size.y)
		
func get_text() -> String:
	return $Text.text

func get_tween_seconds(pixel_width: float) -> float:
	return pixel_width / 16 / 60
