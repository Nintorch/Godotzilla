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
var camera_x_old: float

# These are set in Board.gd and in next_level()
var data = {
	current_character = GameCharacter.Type.MOTHRA,
	board_piece = null,
}

func _ready() -> void:
	Global.widescreen_changed.connect(on_widescreen_change)
	RenderingServer.set_default_clear_color(bg_color)
	
	player.character = data.current_character
	player.board_piece = data.board_piece
	
	player.intro_ended.connect(func():
		if not Global.music.playing:
			Global.play_music(music)
		)
	
	Global.fade_in()
	
func _process(_delta: float) -> void:
	process_camera()
	
	if player.position.x > camera.limit_right - 10:
		player.save_state()
		next_level()

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
		level.data = data
		Global.change_scene_node(level)
	else:
		Global.change_scene_node(Global.board)
		Global.board.returned()
