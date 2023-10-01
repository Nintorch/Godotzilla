extends Node2D

@export var music: AudioStream = preload("res://Audio/Soundtrack/Earth.ogg")
@export var bg_color = Color(0, 0, 0)

@onready var window_width_half = Global.get_content_size().x / 2
@onready var camera: Camera2D = $Camera
@onready var player: GameCharacter = $Player

enum CameraMode {
	NORMAL,
}

var camera_mode = CameraMode.NORMAL
var timer = 0

func _ready() -> void:
	Global.level = self
	Global.camera = camera
	Global.widescreen_changed.connect(on_widescreen_change)
	RenderingServer.set_default_clear_color(bg_color)
	
	Global.fade_in()
	
func _process(delta: float) -> void:
	timer += delta
	process_camera()
	
	if player.position.x > camera.limit_right - 10:
		next_level()
		
	if Input.is_action_just_pressed("Select"):
		Global.player.damage(4, 0.2)
	if Input.is_action_just_pressed("Start"):
		Global.player.add_score(20)
	
func intro_ended() -> void:
	if not Global.music.playing:
		Global.play_music(music)

func process_camera() -> void:
	match camera_mode:
		CameraMode.NORMAL:
			if camera.position.x < player.position.x + 40 \
				and camera.position.x < camera.limit_right - window_width_half:
				camera.position.x = player.position.x + 40
				camera.limit_left = max(camera.position.x - window_width_half, 0)
		
func on_widescreen_change() -> void:
	window_width_half = Global.get_content_size().x / 2
	camera.limit_left = max(camera.position.x - window_width_half, 0)
		
func get_HUD():
	return $HUD
	
func next_level() -> void:
	var level = Global.get_next_level()
	if level:
		level = level.instantiate()
		if level.music != music:
			Global.music_fade_out()
	else:
		if Global.board.music != music:
			Global.music_fade_out()
		
	get_tree().paused = true
	Global.fade_out()
	await Global.fade_end
	get_tree().paused = false
	if level:
		Global.change_scene_node(level)
	else:
		Global.change_scene_node(Global.board)
		Global.board.returned()
