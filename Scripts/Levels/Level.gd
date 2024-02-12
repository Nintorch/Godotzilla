class_name Level
extends Node2D

@export var music: AudioStream = preload("res://Audio/Soundtrack/Earth.ogg")
@export var bg_color = Color(0, 0, 0)
@export var enable_level_end := true

@onready var window_width_half = Global.get_content_size().x / 2
@onready var camera: Camera2D = $Camera
@onready var player: GameCharacter = $Player

const CAMERA_OFFSET_X = 30

enum CameraMode {
	NORMAL,
	TWO_SIDES,
}

var camera_mode = CameraMode.NORMAL
var camera_x_old: float
var camera_current_offset := 0

# These are set in Board.gd and in next_level()
var data = {
	current_character = GameCharacter.Type.GODZILLA,
	board_piece = null,
}

func _ready() -> void:
	Global.widescreen_changed.connect(on_widescreen_change)
	RenderingServer.set_default_clear_color(bg_color)
	
	player.character = data.current_character
	if data.board_piece:
		player.load_state(data.board_piece.character_data)
	
	player.intro_ended.connect(func():
		if not Global.music.playing:
			Global.play_music(music)
		)
		
	player.block_level_end = not enable_level_end
	
	Global.fade_in()
	
func _process(_delta: float) -> void:
	process_camera()
	
	Global.accept_pause()
	
	if enable_level_end and player.position.x > camera.limit_right - 10:
		var board_piece = data.board_piece
		if board_piece:
			player.save_state(board_piece.character_data)
			board_piece.level = board_piece.character_data.level
			
			Global.board.board_data.player_score = player.score
			Global.board.board_data.player_level[board_piece] = player.level
		
		next_level()

func process_camera() -> void:
	camera_x_old = camera.get_screen_center_position().x
	match camera_mode:
		CameraMode.NORMAL:
			if camera.position.x < player.position.x + CAMERA_OFFSET_X \
				and camera.position.x < camera.limit_right - window_width_half:
				camera.position.x = clampf(player.position.x + CAMERA_OFFSET_X,
					window_width_half, camera.limit_right - window_width_half)
				camera.limit_left = max(camera.position.x - window_width_half, 0)
		CameraMode.TWO_SIDES:
			camera_current_offset = move_toward(
				camera_current_offset,
				CAMERA_OFFSET_X * player.direction,
				2
			)
			camera.position.x = player.position.x + camera_current_offset
				
func is_camera_moving() -> bool:
	return camera_x_old != camera.get_screen_center_position().x
		
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
		# If we're just debugging the game,
		# don't show an error and just fade out
		if not Global.board:
			get_tree().paused = true
			Global.fade_out()
			return
		elif Global.board.music != music:
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
