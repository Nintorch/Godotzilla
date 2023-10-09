extends Node2D

@export var music: AudioStream = preload("res://Audio/Soundtrack/Earth.ogg")
@export var board_name := "The Earth"
@export var levels: Array[PackedScene]

@onready var tilemap: TileMap = $Board/TileMap
@onready var message_window: NinePatchRect = $Board/CanvasLayer/MessageWindow
@onready var selector: Sprite2D = $Board/TileMap/Selector

@onready var board_pieces = $"Board/TileMap/Board Pieces".get_children()
# The actual playable board, the node that has this script
# also includes the board name.
@onready var board: Node2D = $Board

@onready var menubip: AudioStreamPlayer = $Board/CanvasLayer/MessageWindow/MenuBip

var selected_piece: Node = null

func _ready():
	Global.board = self
	
	RenderingServer.set_default_clear_color(Color.BLACK)
	build_outline()
	
	Global.characters.append(GameCharacter.Type.GODZILLA)
	Global.planet_levels = levels
	
	if board_name:
		# Show the board name and hide the actual board for now
		$BoardName/Label.text = board_name
		$BoardName/Label.position = Global.get_default_resolution() / 2 \
			- Vector2i($BoardName/Label.size) / 2
		board.visible = false
		board.process_mode = Node.PROCESS_MODE_DISABLED
		Global.fade_in()
		await Global.fade_end
		
		# Show the board name for some time
		await get_tree().create_timer(2).timeout
		
		# ..and then fade out and show the board
		Global.fade_out()
		await Global.fade_end
		
	$BoardName.visible = false
	Global.fade_in()
	board.visible = true
	board.process_mode = Node.PROCESS_MODE_INHERIT
	Global.play_music(music)
		
func _process(_delta: float):
	if board.visible and selector.is_stopped():
		if Input.is_action_just_pressed("A"):
			if not selected_piece:
				var piece = get_current_piece()
				if piece and piece.is_player():
					menubip.play()
					piece.select()
					selected_piece = piece
					message_window.disappear()
				elif piece and not piece.is_player():
					show_boss_info(piece)
				else:
					message_window.appear("There is no monster here.")
				adjust_message_pos()
			else:
				selected_piece.prepare_start()
				Global.playing_levels = selector.playing_levels
				menubip.play()
				start_playing()
			
		if Input.is_action_just_pressed("B") and selected_piece:
			menubip.play()
			selected_piece.deselect()
			selected_piece = null
			message_window.disappear()
			
		if Input.is_action_just_pressed("Start"):
			# Not checking if the piece is a play on purpose
			if not selected_piece and get_current_piece():
				message_window.appear("Then press button A.")
			elif selected_piece:
				message_window.appear("If\nfinished moving, press button A.")
			else:
				message_window.appear("Select\na monster to move.")
			adjust_message_pos()
			
		if message_window.visible and Input.is_action_just_pressed("B"):
			message_window.disappear()
		
func adjust_message_pos():
	if selector.position.y > 120:
		message_window.position.y = 16
	else:
		message_window.position.y = 136

func build_outline():
	for cell in tilemap.get_used_cells(0):
		var cell_id = tilemap.get_cell_atlas_coords(0, cell)
		if cell_id != Vector2i(0, 0) and cell_id != Vector2i(-1, -1):
			print("Warning: Icon moved from TileMap layer 0 to layer 1")
			tilemap.set_cell(1, cell, 0, cell_id)
			
	for cell in tilemap.get_used_cells(1):
		tilemap.set_cell(0, cell, 0, Vector2i(0, 0))

func get_current_piece() -> Node:
	for p in board_pieces:
		if p.get_cell_pos() == selector.get_cell_pos(selector.old_pos):
			return p
	return null
	
func show_boss_info(piece) -> void:
		var text = GameCharacter.CharacterNames[piece.piece_character] + " - "
		var size = Vector2i(message_window.default_window_size)
		var hp_text = boss_hp_str(piece.hp)
		
		if text.length() >= (size.x - 16) / 8:
			size.x = (text.length() + 1) * 8
			
		var space_count = (size.x - 16) / 8 - hp_text.length()
		text += "life\n" + " ".repeat(space_count) + hp_text
		message_window.appear(text, true, size)
		
func boss_hp_str(hp: float) -> String:
	var s = str(snappedf(hp, 0.1))
	if fmod(hp, 1) == 0:
		s += ".0"
	return s
	
func start_playing() -> void:
	get_tree().paused = true
	
	await get_tree().create_timer(0.5).timeout
	
	Global.music_fade_out()
	Global.fade_out()
	await Global.fade_end
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	Global.current_character = selected_piece.piece_character
	# We don't free the board scene so we can later return to it,
	# hence the second false argument.
	Global.change_scene(Global.get_next_level(), false)
	
# TODO: Boss' steps
func returned() -> void:
	await get_tree().create_timer(0.5).timeout
	
	Global.fade_in()
	if not Global.music.playing or Global.music.stream != music:
		Global.play_music(music)
	if selected_piece:
		selected_piece.deselect()
		selected_piece = null

func get_player_pieces() -> Array[Node2D]:
	# The result of filter cannot be returned because it's Array[Node]
	# but the call to assign can convert to Array[Node2D]
	var ret: Array[Node2D] = []
	ret.assign(board_pieces.filter(func(p): return p.is_player()))
	return ret
	
func get_boss_pieces() -> Array[Node2D]:
	var ret: Array[Node2D] = []
	ret.assign(board_pieces.filter(func(p): return not p.is_player()))
	return ret