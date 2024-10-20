class_name Level
extends Node2D

enum LevelBoundaryType {
	## The player will act like there's a big wall preventing them from going further
	WALL,
	## The player will go to the next level upon touching the boundary
	NEXT_LEVEL,
}

const GAME_OVER_SCENE := preload("res://Scenes/GameOver.tscn")

@export var music: AudioStream
@export var bg_color := Color(0, 0, 0)
@export var right_boundary_behaviour := LevelBoundaryType.NEXT_LEVEL

@onready var camera: Camera2D = $Camera
@onready var player: PlayerCharacter = $Player

class GameplayData:
	var current_character := PlayerCharacter.Type.GODZILLA
	var board_piece: BoardPiece = null
	var boss_piece: BoardPiece = null

var data: GameplayData = null

func _ready() -> void:
	RenderingServer.set_default_clear_color(bg_color)
	PauseManager.pause_finished.connect(func() -> void:
		RenderingServer.set_default_clear_color(bg_color)
		)
	
	data = Global.level_data if Global.level_data != null else GameplayData.new()
		
	player.character = data.current_character
	player.health.dead.connect(func() -> void: 
		Global.play_music(preload("res://Audio/Soundtrack/PlayerDeath.ogg"))
		player_dead(player)
		)
	if data.board_piece:
		player.load_state(data.board_piece.character_data)
	
	player.intro_ended.connect(func() -> void:
		if not Global.music.playing and music != null:
			Global.play_music(music)
		)
	
	Global.fade_in()
	
func _process(_delta: float) -> void:
	if player.state.current != PlayerCharacter.State.DEAD:
		PauseManager.accept_pause()
	
	# Level left boundary
	if player.state.current != PlayerCharacter.State.LEVEL_INTRO \
		and player.position.x < camera.limit_left + 10:
			player.position.x = camera.limit_left + 10
			player.velocity.x = 0.0
	
	# Level right boundary
	if player.position.x > camera.limit_right - 10:
		match right_boundary_behaviour:
			LevelBoundaryType.WALL:
				player.position.x = camera.limit_right - 10
				player.velocity.x = 0.0
			
			LevelBoundaryType.NEXT_LEVEL:
				save_player_state()
				next_level()

func save_player_state() -> void:
	var board_piece: Node2D = data.board_piece
	if board_piece:
		player.save_state(board_piece.character_data)
		board_piece.level = board_piece.character_data.level
	
		board_piece.save_data()

# Can also be used on bosses, hence the "character" argument
func player_dead(character: PlayerCharacter,
				piece: BoardPiece = data.board_piece) -> void:
	await Global.music.finished
	await Global.fade_out_paused()
	
	if not is_instance_valid(Global.board):
		return
	
	if is_instance_valid(piece): piece.remove()
	Global.board.selected_piece = null
		
	if Global.board.get_player_pieces().size() == 0:
		Global.change_scene(GAME_OVER_SCENE)
		return
		
	Global.change_scene_node(Global.board)
	Global.board.returned(not character.is_player)

#region Code for going to the next level/planet

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
		Global.change_scene_node(level)
	else:
		if Global.board.music != music:
			Global.music_fade_out()
			
		await Global.fade_out_paused()
		data.board_piece.save_data() # Just in case
		Global.change_scene_node(Global.board)
		Global.board.returned()
		
#endregion
