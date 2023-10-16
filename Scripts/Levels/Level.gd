class_name Level
extends Node2D

@export var music: AudioStream = preload("res://Audio/Soundtrack/Earth.ogg")
@export var bg_color = Color(0, 0, 0)

@onready var window_width_half = Global.get_content_size().x / 2
@onready var camera: Camera2D = $Camera
@onready var player: GameCharacter = $Player

const CAMERA_OFFSET_X = 30

enum CameraMode {
	NORMAL,
}

var camera_mode = CameraMode.NORMAL
var current_character: int
var camera_x_old: float

func _ready() -> void:
	Global.camera = camera
	Global.widescreen_changed.connect(on_widescreen_change)
	RenderingServer.set_default_clear_color(bg_color)
	
	current_character = GameCharacter.Type.MOTHRA
	player.character = current_character
	
	Global.fade_in()
	
func _process(_delta: float) -> void:
	process_camera()
	
	if player.position.x > camera.limit_right - 10:
		next_level()
		
	if Input.is_action_just_pressed("Start"):
		Global.player.damage(4)
	
func intro_ended() -> void:
	if not Global.music.playing:
		Global.play_music(music)

func process_camera() -> void:
	camera_x_old = camera.position.x
	match camera_mode:
		CameraMode.NORMAL:
			if camera.position.x < player.position.x + CAMERA_OFFSET_X \
				and camera.position.x < camera.limit_right - window_width_half:
				camera.position.x = clampf(player.position.x + CAMERA_OFFSET_X,
					window_width_half, camera.limit_right - window_width_half)
				camera.limit_left = max(camera.position.x - window_width_half, 0)
				
func is_camera_moving() -> bool:
	return camera_x_old < camera.position.x
		
func on_widescreen_change() -> void:
	window_width_half = Global.get_content_size().x / 2
	camera.limit_left = max(camera.position.x - window_width_half, 0)
		
func get_HUD():
	return $HUD
	
func next_level() -> void:
	# level: PackedScene
	var level = Global.get_next_level()
	if level:
		level = level.instantiate()
		if level.music != music:
			Global.music_fade_out()
	else:
		if Global.board.music != music:
			Global.music_fade_out()
	# level: Node
		
	get_tree().paused = true
	
	Global.fade_out()
	await Global.fade_end
	
	get_tree().paused = false
	
	if level:
		Global.change_scene_node(level)
	else:
		Global.change_scene_node(Global.board)
		Global.board.returned()
