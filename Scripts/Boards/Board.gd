class_name Board
extends Node2D

#region Variables

@export_category("General board settings")
@export var board_name: String = "Template"
@export var music: AudioStream
@export var tileset: Texture
## The scene the player will be sent to after completing this board
@export var next_scene: PackedScene
## If set, after the player makes their turn, one of the bosses
## will also have their turn
@export var allow_boss_movement := true

@export_category("Saves")
## If true, a player's current save will be changed when this
## scene starts
@export var use_in_saves := true
@export var board_id := "template"

## The array of levels
## Check out get_level_id(tile: Vector2i) -> int in Selector.gd
## to get the level ID for a cell in the tilemap
@export_category("Levels")
@export var levels: Array[PackedScene]

@onready var outline: TileMapLayer = $Board/Outline
@onready var tilemap: TileMapLayer = $"Board/Board Icons"
@onready var message_window: MessageWindow = $Board/GUI/MessageWindow
@onready var selector: BoardSelector = $"Board/Board Icons/Selector"

# The actual playable board, the node that has this script
# also includes the board name.
@onready var board: Node2D = $Board

@onready var menubip: AudioStreamPlayer = $Board/GUI/MessageWindow/MenuBip

var selected_piece: BoardPiece = null
var board_data := {
	"players": {}, # [String (board piece name)] -> Dictionary ("xp", "level")
	"player_characters": [],
}

#endregion

#region Main board code

func _ready() -> void:
	Global.board = self
	Global.level_data = null
	
	# Save current player characters so we can show them
	# in a save slot
	var player_characters: Array[PlayerCharacter.Type] = []
	player_characters.assign(get_player_pieces().map(
		func(p: BoardPiece) -> PlayerCharacter.Type: return p.piece_character
		))
	player_characters.sort()
	
	if use_in_saves:
		var save_data := SaveManager.save_data
		
		if save_data.has("board_data") and not save_data["board_data"].is_empty():
			board_data = save_data["board_data"]
			board_data["player_characters"] = player_characters
				
		if not save_data.has("board_id") or save_data["board_id"] != board_id:
				save_data["board_id"] = board_id
				save_data["board_data"] = board_data
				board_data["player_characters"] = player_characters
				SaveManager.store_save_data()

	RenderingServer.set_default_clear_color(Color.BLACK)
	tilemap.tile_set.get_source(0).texture = tileset
	tilemap.tile_set.get_source(1).texture = tileset
	outline.tile_set = tilemap.tile_set
	build_outline()
	
	if board_name:
		# Show the board name and hide the actual board for now
		$BoardName.visible = true
		$BoardName.size = Global.get_default_resolution()
		$BoardName/Label.text = board_name
			
		board.visible = false
		board.process_mode = Node.PROCESS_MODE_DISABLED
		
		await Global.fade_in()
		# Show the board name for some time
		await get_tree().create_timer(2).timeout
		# ..and then fade out and show the board
		await Global.fade_out()
		
	Global.fade_in()
	$BoardName.visible = false
	board.visible = true
	board.process_mode = Node.PROCESS_MODE_INHERIT
	Global.play_music(music)
	
func _process(_delta: float) -> void:
	if not board.visible:
		return
		
	if not selector.ignore_player_input and not Global.is_fade_shown():
		PauseManager.accept_pause()
	
	if not selector.is_stopped() or selector.ignore_player_input:
		return
		
	if Input.is_action_just_pressed("A"):
		# If no board pieces are selected
		if not selected_piece:
			var piece := get_current_piece()
			if piece and piece.is_player():
				piece.select()
				selector.moved_at_all = false
				selected_piece = piece
				message_window.disappear()
			elif piece and not piece.is_player():
				show_boss_info(piece)
			else:
				message_window.appear("There is no monster here.")
			adjust_message_pos()
		elif not message_window.visible \
			or message_window.text.text.begins_with("Unable to advance"):
				if not selector.moved_at_all:
					var result: MessageWindow.Response = await message_window.appear(
						"Not going\nto move?", true, true)
					if result == MessageWindow.Response.YES:
						selector.moved_at_all = true
						if selector.check_for_bosses(): return
						not_going_to_move()
						return
					elif result == MessageWindow.Response.NO:
						selected_piece.deselect()
						selected_piece = null
				else:
					# If a board piece is selected and A was pressed, start playing
					menubip.play()
					start_playing()
		
	# Cancel the player's current move
	if Input.is_action_just_pressed("B") and selected_piece:
		menubip.play()
		cancel_move()
		
	# Mini tutorial on how to use the board (from GMoM)
	if Input.is_action_just_pressed("Start"):
		if not selected_piece and get_current_piece() != null:
			# We don't check if it's a boss on purpose
			# (to be accurate to the original game)
			message_window.appear("Then press button A.")
		elif selected_piece:
			message_window.appear("If\nfinished movig, press button A.")
		else:
			message_window.appear("Select\na monster to move.")
		adjust_message_pos()
		
	if message_window.visible and Input.is_action_just_pressed("B"):
		message_window.disappear()
		
func cancel_move() -> void:
	selected_piece.deselect()
	selected_piece = null
	message_window.disappear()
	selector.set_process(true)
		
func adjust_message_pos() -> void:
	if selector.position.y > 120:
		message_window.position.y = 16
	else:
		message_window.position.y = 144

func build_outline() -> void:
	for cell in outline.get_used_cells():
		var cell_id := outline.get_cell_atlas_coords(cell)
		if cell_id != Vector2i(0, 0) and cell_id != Vector2i(-1, -1):
			print("Warning: Icon moved from outline layer to board icons layer")
			tilemap.set_cell(cell, 0, cell_id)
			
	outline.clear()
			
	for cell in tilemap.get_used_cells():
		outline.set_cell(cell, 0, Vector2i(0, 0))
		
# The player skipped their move, make the bosses do their move
func not_going_to_move() -> void:
	await fade_out_selected(false)
	returned()
	
# The player made their move
func start_playing(boss_piece: BoardPiece = null) -> void:
	# The levels the player is going to go through
	Global.playing_levels.assign(
		selector.playing_levels.map(func(x: int) -> PackedScene:
			# Ignore non-existant levels
			if x >= levels.size():
				print("Level with id " + str(x) + " is out of bounds")
				return null
			return levels[x]
			))
			
	# If the player also collided with a boss during their move
	if boss_piece != null:
		Global.playing_levels.append(boss_piece.boss_scene)
		
	# Let the developer know there's a missing level scene on the board
	if Global.playing_levels.find(null) >= 0:
		Global.playing_levels.clear()
				
	if Global.playing_levels.size() == 0:
		not_going_to_move()
		return

	await fade_out_selected()
	
	# We later load that data in Level.gd
	Global.level_data = Level.GameplayData.new()
	Global.level_data.current_character = selected_piece.piece_character
	Global.level_data.board_piece = selected_piece
	Global.level_data.boss_piece = boss_piece
	selected_piece = null
	
	# We don't free the board scene so we can later return to it,
	# hence the second false argument.
	Global.change_scene(Global.get_next_level(), false)
	
# Fade out after the player made their move
func fade_out_selected(music_fade_out := true) -> void:
	selected_piece.prepare_start()
	get_tree().paused = true
	
	await get_tree().create_timer(0.5).timeout
	
	if music_fade_out:
		Global.music_fade_out()
	await Global.fade_out()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	
# The game returned back to the board after a level was finished.
# ignore_boss_moves indicates that the game returned to the board
# after a boss scene where the boss timer ran out
func returned(ignore_boss_moves := false) -> void:
	await get_tree().create_timer(0.5).timeout
	
	message_window.make_hide()
	Global.fade_in()
	if not Global.music.playing or Global.music.stream != music:
		Global.play_music(music)
	if selected_piece:
		selected_piece.deselect()
		selected_piece = null
		
	if ignore_boss_moves:
		selector.playing_levels.clear()
		selector.ignore_player_input = false
		selector.set_process(true)
		selector.visible = true
		selector.moved.emit()
		return

	# Here we prepare for a boss (if present) to make a move
	# (if allowed by the board's properties)
	if allow_boss_movement and get_boss_pieces().size() > 0:
		# The bosses also use the selector to move, so we should
		# save its current position so later the player won't
		# notice that selector was used/moved
		var selector_pos_saved := Vector2(selector.position)
		selector.hide()
		selector.ignore_player_input = true

		await Global.fade_end
		if await move_boss():
			selector.show()
		selector.position = selector_pos_saved
	else:
		selector.show()
		
	selector.ignore_player_input = false
	selector.playing_levels.clear()
		
#endregion

#region Bosses
		
# Information about a boss after the player pressed on their board piece
func show_boss_info(piece: BoardPiece) -> void:
	var text := PlayerCharacter.CHARACTER_NAMES[piece.piece_character] + " - "
	var size := Vector2i(message_window.default_window_size)
	var hp_text := boss_hp_str(piece.character_data.hp / 8)
	
	if text.length() >= (size.x - 16) / 8:
		size.x = (text.length() + 1) * 8
		
	var space_count := (size.x - 16) / 8 - hp_text.length()
	text += "life\n" + " ".repeat(space_count) + hp_text
	message_window.appear(text, true, false, size)
		
func boss_hp_str(hp: float) -> String:
	var s := str(snappedf(hp, 0.1))
	if fmod(hp, 1) < 0.1:
		s += ".0"
	return s
	
# Make the boss piece move using pathfinding
func move_boss() -> bool:
	var boss_piece: BoardPiece = get_boss_pieces().pick_random()
	
	# Don't include other boss pieces in the navigation path so they don't collide
	# (by usign an alternative tile without navigation region)
	for p: BoardPiece in get_boss_pieces():
		if p != boss_piece:
			outline.set_cell(p.get_cell_pos(), 0, Vector2i(0, 0), 1)
		
	var player_piece: BoardPiece = get_closest_player(boss_piece)
	await get_tree().create_timer(0.5).timeout
	boss_piece.select()
	selected_piece = boss_piece
	
	var nav_agent: NavigationAgent2D = boss_piece.get_nav_agent()
	nav_agent.set_navigation_map(outline.get_navigation_map())
	nav_agent.target_position = player_piece.global_position
	nav_agent.get_next_path_position() # Build the navigation path
	var path := convert_navigation_path(nav_agent.get_current_navigation_path())
	
	for p: BoardPiece in get_boss_pieces():
		if p != boss_piece:
			outline.set_cell(p.get_cell_pos(), 0, Vector2i(0, 0))
	
	selector.playing_levels.clear()
	
	for i in mini(boss_piece.steps, path.size()):
		await get_tree().create_timer(0.5).timeout
		# Direction of movement
		var direction := path[i] - boss_piece.position
		# Request movement
		selector.move(direction.x, direction.y)
		await selector.moved
		selector.move(0, 0)

		# Wait until we get onto the next hex
		await selector.stopped
	
	await get_tree().create_timer(0.5).timeout
	boss_piece.prepare_start()
		
	if selector.playing_levels.size() <= boss_piece.steps:
		selected_piece = player_piece
		selector.playing_levels.clear()
		start_playing(boss_piece)
		return false
	else:
		selector.playing_levels.clear()
		selected_piece = null
		await get_tree().create_timer(0.5).timeout
		await Global.fade_out()
		Global.fade_in()
		return true
	
func get_closest_player(boss_piece: BoardPiece) -> Node2D:
	var array := get_player_pieces()
	if array.size() == 0:
		return null
	array.sort_custom(func(a: BoardPiece, b: BoardPiece) -> bool:
		var distance_a := a.position.distance_to(boss_piece.position)
		var distance_b := b.position.distance_to(boss_piece.position)
		return distance_a < distance_b
		)
	return array[0]
	
# Convert navigation path of global positions to
# path of positions snapped to tilemap cells
func convert_navigation_path(path: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in path:
		var pos: Vector2 = selector.map_to_tilemap(tilemap.to_local(point))
		if (result.size() > 0 and result[-1] != pos or result.size() == 0) \
			and selector.cell_exists(selector.get_cell_pos(pos)):
				result.append(pos)
	# We don't want the boss to try to move to its current position
	result.remove_at(0)
	result.remove_at(result.size()-1)
	return result
	
#endregion

#region Board-specific piece-related code

func get_board_pieces() -> Array[BoardPiece]:
	var board_pieces: Array[BoardPiece] = []
	board_pieces.assign(
		%"Board Pieces".get_children().filter(func(x: Node) -> bool:
			return not x.is_queued_for_deletion() and x is BoardPiece
			))
	return board_pieces

# If selector is currently positioned on a board piece
# then we can check that using this function
func get_current_piece() -> BoardPiece:
	for p: BoardPiece in get_board_pieces():
		if p.get_cell_pos() == selector.get_cell_pos(selector.old_pos):
			return p
	return null
	
func get_player_pieces() -> Array[BoardPiece]:
	return get_board_pieces().filter(func(p: BoardPiece) -> bool: return p.is_player())
	
func get_boss_pieces() -> Array[BoardPiece]:
	return get_board_pieces().filter(func(p: BoardPiece) -> bool: return not p.is_player())

# 2 board pieces collided with each other
# Boss collisions with other bosses are prohibited by the move_boss function
func _on_selector_piece_collision(boss_collision: bool) -> void:
	adjust_message_pos()
	if not boss_collision and not message_window.visible:
		message_window.appear(
			"Unable to advance because a monster is blocking the way.",
			false
			)
	elif boss_collision:
		var result: MessageWindow.Response = await message_window.appear(
			"Will you fight\nthe enemy?",
			false, true)
		if result == MessageWindow.Response.YES:
			var bosses := selector.get_neighbor_bosses()
			# Keep looping through the bosses until the player either
			# chooses to fight or cancels their move
			# ("No" response to all of the bosses is ignored basically)
			while true:
				for piece in bosses:
					result = await message_window.appear(
						"Will you fight\n%s?" % piece.get_character_name(),
						false, true)
					if result == MessageWindow.Response.YES:
						start_playing(piece)
						return
					elif result == MessageWindow.Response.CANCEL:
						cancel_move()
						return
		elif result == MessageWindow.Response.NO:
			message_window.appear("Unable to advance, contacting the enemy.")
			selector.set_process(true)
		elif result == MessageWindow.Response.CANCEL:
			cancel_move()
		
#endregion
