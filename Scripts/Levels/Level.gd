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
	current_character = GameCharacter.Type.GODZILLA,
	board_piece = null,
}

func _ready() -> void:
	Global.widescreen_changed.connect(on_widescreen_change)
	RenderingServer.set_default_clear_color(bg_color)
	
	player.character = data.current_character
	
	player.intro_ended.connect(func():
		if not Global.music.playing:
			Global.play_music(music)
		)
		
	if get_HUD():
		var life_bar = get_HUD().get_node("PlayerCharacter/Life")
		var power_bar = get_HUD().get_node("PlayerCharacter/Power")
		life_bar.width = player.health.max_value / 8
		life_bar.max_value = player.health.max_value
		
		power_bar.width = player.power.max_value / 8
		power_bar.max_value = player.power.max_value
		
		player.life_amount_changed.connect(func(new_value: float):
			life_bar.target_value = new_value
			)
			
		player.level_amount_changed.connect(next_player_level)
	
	Global.fade_in()
	
func _process(_delta: float) -> void:
	process_camera()
	
	if get_HUD():
		var power_bar = get_HUD().get_node("PlayerCharacter/Power")
		power_bar.target_value = player.power.value
	
	if player.position.x > camera.limit_right - 10:
		var board_piece = data.board_piece
		if board_piece:
			player.save_state(board_piece.character_data)
			board_piece.level = board_piece.character_data.level
			
			Global.board.board_data.player_score = player.score
			Global.board.board_data.player_level[board_piece] = player.level
		
		next_level()
	
	if Input.is_action_just_pressed("B"):
		player.set_level(2)

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
	
func next_player_level(new_value: int, new_bar_count: int):
	if not get_HUD():
		return
		
	var life_bar = get_HUD().get_node("PlayerCharacter/Life")
	var power_bar = get_HUD().get_node("PlayerCharacter/Power")
	life_bar.width = new_bar_count
	life_bar.max_value = new_bar_count * 8

	power_bar.width = new_bar_count
	power_bar.max_value = new_bar_count * 8
	
	var level_node = get_HUD().get_node("PlayerCharacter/Level")
	var level_str := str(new_value)
	if level_str.length() < 2:
		level_str = "0" + level_str
	level_node.text = "level " + level_str
	
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
