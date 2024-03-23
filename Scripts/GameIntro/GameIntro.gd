extends Node2D

const TEXT := "In 2XXX A.D., 
the earth receives a declaration 
of war from Planet X.  
With the entire solar system 
as the battlefield, bloody combat begins 
between space monsters and 
our guardians, Godzilla and Mothra!
"

const TEXT_SPEED := 1 * 60

@export var next_scene: PackedScene

@onready var story_text = $Bars/StoryText
@onready var images: Node2D = $Images
@onready var bars: Node2D = $Bars
@onready var image_change_timer: Timer = $ImageChangeTimer

var started := false
var finished := false
var image_count := 0
var current_image := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	for obj: Node in $Bars.get_children():
		if obj is ColorRect:
			obj.size.x = Global.get_content_size().x
		
	story_text.text = TEXT.replace('\n', '')
	images.visible = false
	image_count = images.get_child_count()
	
	Global.play_music(preload("res://Audio/Soundtrack/Mars.ogg"))
	Global.fade_in()
	await get_tree().create_timer(1, false).timeout
	started = true
	
	bars.reparent(Global.main.canvas_layer)
	Global.fade_in()
	Global.show_fade()
	show_current_image()
	images.visible = true

func _process(delta: float) -> void:
	if not started:
		return
		
	story_text.position.x -= TEXT_SPEED * delta

func show_current_image() -> void:
	images.get_children().map(func(img: Node2D):
		img.visible = false
		img.set_process(false)
		)
	var current_sequence := images.get_child(current_image)
	current_sequence.visible = true
	current_sequence.set_process(true)

func next_image() -> void:
	if current_image < (image_count-1):
		Global.fade_out()
		await Global.fade_end
		current_image += 1
		await get_tree().create_timer(0.5, false).timeout
		show_current_image()
		Global.fade_in()
	else:
		bars.reparent(self)
		Global.fade_out()
		Global.music_fade_out()
		await Global.fade_end
		await get_tree().create_timer(0.5, false).timeout
		Global.change_scene(next_scene)
