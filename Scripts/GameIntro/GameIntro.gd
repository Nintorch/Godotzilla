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
	for bar: Node in [$Bars/Bar1, $Bars/Bar2]:
		bar.size.x = Global.get_default_resolution().x
	setup_widescreen_bars()
		
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
	
func setup_widescreen_bars() -> void:
	var bar1: Control = $Bars/WidescreenBar1
	var bar2: Control = $Bars/WidescreenBar2
	bar1.position.x = -(Global.get_content_size().x - Global.get_default_resolution().x) / 2 - 1
	bar1.size.x = -bar1.position.x
	bar1.size.y = Global.get_content_size().y
	bar2.position.x = Global.get_default_resolution().x
	bar2.size = bar1.size

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
		await Global.fade_out()
		current_image += 1
		await get_tree().create_timer(0.5, false).timeout
		show_current_image()
		Global.fade_in()
	else:
		bars.reparent(self)
		Global.music_fade_out()
		await Global.fade_out()
		await get_tree().create_timer(0.5, false).timeout
		Global.change_scene(next_scene)
