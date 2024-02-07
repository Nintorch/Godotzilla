extends Node2D

@export_category("General board settings")
@export var board_name: String = "Template"
@export var music: AudioStream
@export var tileset: Texture
@export var next_board: PackedScene
@export var allow_boss_movement := true

## If true, a player's current save will be changed when this
## scene starts
@export_category("Saves")
@export var use_in_saves := true
@export var board_id := "template"

## The array of levels
## Check out get_level_id(tile: Vector2i) -> int in Selector.gd
## to get the level ID for a cell in the tilemap
@export_category("Levels")
@export var levels: Array[PackedScene]

@onready var tilemap: TileMap = $Board/TileMap
@onready var message_window: NinePatchRect = $Board/GUI/MessageWindow
@onready var selector: Sprite2D = $Board/TileMap/Selector
	
# The actual playable board, the node that has this script
# also includes the board name.
@onready var board: Node2D = $Board
@onready var board_pieces: Node2D = $"Board/TileMap/Board Pieces"

@onready var menubip: AudioStreamPlayer = $Board/GUI/MessageWindow/MenuBip

var selected_piece: Node = null
var board_data = {
	player_score = 0.0,
	player_level = {}, # [GameCharacter.Type] -> int
}

func _ready():
	Global.board = self
	
	RenderingServer.set_default_clear_color(Color.BLACK)
	tilemap.tile_set.get_source(0).texture = tileset
	tilemap.tile_set.get_source(1).texture = tileset
	build_outline()
	
	if board_name:
		# Show the board name and hide the actual board for now
		$BoardName.visible = true
		$BoardName.size = Global.get_default_resolution()
		$BoardName/Label.text = board_name
			
		board.visible = false
		board.process_mode = Node.PROCESS_MODE_DISABLED
		
		Global.fade_in()
		await Global.fade_end
		
		# Show the board name for some time
		await get_tree().create_timer(2).timeout
		
		# ..and then fade out and show the board
		Global.fade_out()
		await Global.fade_end
		
	Global.fade_in()
	$BoardName.visible = false
	board.visible = true
	board.process_mode = Node.PROCESS_MODE_INHERIT
	Global.play_music(music)
		
func _process(_delta: float):
	if board.visible and selector.is_stopped():
		if Input.is_action_just_pressed("A"):
			if not selected_piece:
				var piece = get_current_piece()
				if piece and piece.is_player():
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
				Global.playing_levels.assign(
					selector.playing_levels.map(func(x):
						if x >= levels.size():
							return null
						return levels[x]
						))
				if Global.playing_levels.find(null) >= 0:
					Global.playing_levels.clear()
					
				start_playing()
			
		if Input.is_action_just_pressed("B") and selected_piece:
			menubip.play()
			selected_piece.deselect()
			selected_piece = null
			message_window.disappear()
			
		if Input.is_action_just_pressed("Start"):
			if not selected_piece and get_current_piece():
				# We don't check if it's a boss on purpose
				# (to be accurate to the original game)
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
		message_window.position.y = 144

func build_outline():
	for cell in tilemap.get_used_cells(0):
		var cell_id = tilemap.get_cell_atlas_coords(0, cell)
		if cell_id != Vector2i(0, 0) and cell_id != Vector2i(-1, -1):
			print("Warning: Icon moved from TileMap layer 0 to layer 1")
			tilemap.set_cell(1, cell, 0, cell_id)
			
	tilemap.clear_layer(0)
			
	for cell in tilemap.get_used_cells(1):
		tilemap.set_cell(0, cell, 0, Vector2i(0, 0))
		
func get_board_pieces() -> Array[Node2D]:
	var board_pieces: Array[Node2D]
	board_pieces.assign(
		$"Board/TileMap/Board Pieces".get_children().filter(func(x: Node2D):
			return not x.is_queued_for_deletion()
			))
	return board_pieces

func get_current_piece() -> Node2D:
	for p in get_board_pieces():
		if p.get_cell_pos() == selector.get_cell_pos(selector.old_pos):
			return p
	return null
	
func show_boss_info(piece) -> void:
	var text = GameCharacter.CHARACTER_NAMES[piece.piece_character] + " - "
	var size = Vector2i(message_window.default_window_size)
	var hp_text = boss_hp_str(piece.character_data.hp / 8)
	
	if text.length() >= (size.x - 16) / 8:
		size.x = (text.length() + 1) * 8
		
	var space_count = (size.x - 16) / 8 - hp_text.length()
	text += "life\n" + " ".repeat(space_count) + hp_text
	message_window.appear(text, true, size)
		
func boss_hp_str(hp: float) -> String:
	var s := str(snappedf(hp, 0.1))
	if fmod(hp, 1) == 0:
		s += ".0"
	return s
	
func start_playing() -> void:
	if Global.playing_levels.size() == 0:
		selected_piece.deselect()
		selected_piece = null
		return
		
	get_tree().paused = true
	
	await get_tree().create_timer(0.5).timeout
	
	Global.music_fade_out()
	Global.fade_out()
	await Global.fade_end
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	
	var level := Global.get_next_level().instantiate()
	level.data = {
		current_character = selected_piece.piece_character,
		board_piece = selected_piece,
	}
	# We don't free the board scene so we can later return to it,
	# hence the second false argument.
	Global.change_scene_node(level, false)
	
func returned() -> void:
	await get_tree().create_timer(0.5).timeout
	
	message_window.make_hide()
	Global.fade_in()
	if not Global.music.playing or Global.music.stream != music:
		Global.play_music(music)
	if selected_piece:
		selected_piece.deselect()
		selected_piece = null
		
	if allow_boss_movement and get_boss_pieces().size() > 0:
		selector.hide()
		selector.ignore_player_input = true
		var selector_pos_saved := selector.position
		
		await Global.fade_end
		
		move_boss()
		
		await Global.fade_end
		Global.fade_in()
		
		selector.position = selector_pos_saved
		selector.show()
		selector.ignore_player_input = false
	
func move_boss() -> void:
	var boss_piece: Node2D = get_boss_pieces().pick_random()
	
	# Don't include other boss pieces in the navigation path
	# (by usign an alternative tile without navigation region)
	for p: Node2D in get_boss_pieces():
		if p != boss_piece:
			var pos = p.get_cell_pos()
			tilemap.set_cell(0, pos, 0, Vector2i(0, 0), 1)
		
	var player_piece: Node2D = get_closest_player(boss_piece)
	await get_tree().create_timer(0.5).timeout
	boss_piece.select()
	
	var nav_agent: NavigationAgent2D = boss_piece.get_nav_agent()
	nav_agent.set_navigation_map(tilemap.get_layer_navigation_map(0))
	nav_agent.target_position = player_piece.global_position
	nav_agent.get_next_path_position() # Build the navigation path
	var path := convert_navigation_path(nav_agent.get_current_navigation_path())
	
	for p: Node2D in get_boss_pieces():
		if p != boss_piece:
			var pos = p.get_cell_pos()
			tilemap.set_cell(0, pos, 0, Vector2i(0, 0))
	
	for i in boss_piece.steps:
		if i >= path.size():
			break
		await get_tree().create_timer(0.5).timeout
		# Direction of movement
		var direction = path[i] - boss_piece.position
		# Request movement
		selector.move(direction.x, direction.y)
		# Wait for a bit and stop requesting movement
		# (if we don't do that the boss will continue moving
		# in the direction we calculated above)
		await get_tree().create_timer(0.1).timeout
		selector.move(0, 0)
		# Wait until we get onto the next hex
		await selector.stopped
	
	await get_tree().create_timer(0.5).timeout
	boss_piece.prepare_start()
	await get_tree().create_timer(0.5).timeout
	Global.fade_out()
	
func get_closest_player(boss_piece: Node2D) -> Node2D:
	var array := get_player_pieces()
	if array.size() == 0:
		return null
	array.sort_custom(func(a: Node2D, b: Node2D) -> bool:
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
	# We don't want the boss to move to its position
	result.remove_at(0)
	return result

func get_player_pieces() -> Array[Node2D]:
	return get_board_pieces().filter(func(p): return p.is_player())
	
func get_boss_pieces() -> Array[Node2D]:
	return get_board_pieces().filter(func(p): return not p.is_player())

func _on_selector_piece_collision(piece):
	if piece.is_player() and not message_window.visible:
		message_window.appear("Unable to advance because a "
			+ "monster is blocking the way.", false)
		adjust_message_pos()
