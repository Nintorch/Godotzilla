extends Node2D

@export var music: AudioStream
@export_multiline var texts: Array[String]

@onready var text_node: RichTextLabel = $CenterContainer/TextNode

var current_text := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	$CenterContainer.size = Vector2(Global.get_default_resolution())
	
	Global.play_music(music)
	display_text()
	Global.fade_in()
	
func _process(_delta: float) -> void:
	if not Global.is_fading():
		if Global.any_action_button_pressed():
			next_text()
		elif Input.is_action_just_pressed("Exit"):
			exit()

func display_text() -> void:
	var text := "[center]%s[/center]" % texts[current_text]
	text_node.text = text
	
func next_text() -> void:
	current_text += 1
	if current_text >= texts.size():
		exit()
		return
	else:
		await Global.fade_out()
	display_text()
	await Global.fade_in()
	
func exit() -> void:
	get_tree().paused = true
	Global.music_fade_out()
	await Global.fade_out()
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = false
	Global.hide_fade()
	Global.change_scene(Global.get_initial_scene())
