class_name Level
extends Node2D

const GAME_OVER_SCENE := preload("res://Scenes/GameOver.tscn")

@export var music: AudioStream
@export var bg_color := Color(0, 0, 0)
@export var enable_level_end := true

@onready var camera: Camera2D = $Camera
@onready var player: PlayerCharacter = $Player

# These are set in Board.gd and in next_level()
var data = {
	current_character = PlayerCharacter.Type.GODZILLA,
	board_piece = null,
	boss_piece = null,
}

func _ready() -> void:
	RenderingServer.set_default_clear_color(bg_color)
	
	player.character = data.current_character
	player.health.dead.connect(func(): 
		Global.play_music(preload("res://Audio/Soundtrack/PlayerDeath.ogg"))
		player_dead(player)
		)
	if data.board_piece:
		player.load_state(data.board_piece.character_data)
	
	player.intro_ended.connect(func():
		if not Global.music.playing and music != null:
			Global.play_music(music)
		)
		
	player.block_level_end = not enable_level_end
	
	Global.fade_in()
	
func _process(_delta: float) -> void:
	Global.accept_pause()
	
	if enable_level_end and player.position.x > camera.limit_right - 10:
		var board_piece = data.board_piece
		if board_piece:
			player.save_state(board_piece.character_data)
			board_piece.level = board_piece.character_data.level
			
			var board_data = Global.board.board_data
			board_data.player_level[board_piece.piece_character] = player.level
		
		next_level()
				
func get_HUD():
	return $HUD
	
func next_level() -> void:
	if OS.is_debug_build() and not Global.board:
		get_tree().paused = true
		Global.fade_out()
		return
		
	assert(is_instance_valid(Global.board))
	
	var level_scene := Global.get_next_level()
	if level_scene:
		var level := level_scene.instantiate()
		if level.music != music:
			Global.music_fade_out()
			
		await Global.fade_out_paused()
		level.data = data
		Global.change_scene_node(level)
	else:
		if Global.board.music != music:
			Global.music_fade_out()
			
		await Global.fade_out_paused()
		Global.change_scene_node(Global.board)
		Global.board.returned()
		
# Can also be used on bosses, hence the "character" argument
func player_dead(character: PlayerCharacter) -> void:
	await Global.music.finished
	await Global.fade_out_paused()
	
	if not is_instance_valid(Global.board):
		return
	
	Global.board.selected_piece.remove()
	Global.board.selected_piece = null
		
	if Global.board.get_player_pieces().size() == 0:
		Global.change_scene(GAME_OVER_SCENE)
		return
		
	Global.change_scene_node(Global.board)
	Global.board.returned(not character.is_player)
