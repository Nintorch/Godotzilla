extends Sprite2D

enum MovementStyle {
	OUTSIDE_CELLS,
	ONLY_INSIDE_CELLS,
}

@export var movement_style := MovementStyle.OUTSIDE_CELLS
@export var board_outline: TileMapLayer
@export var tilemap: TileMapLayer
@export var message_window: Control
@export var board: Node2D

# Speed (in pixels per frame for 60 fps)
var speed := Vector2()
var next_speed := Vector2()
# Current cell position in pixels
var old_pos: Vector2
var moved_at_all := false
var ignore_player_input := false
var playing_levels: Array[int] = []

signal piece_collision(piece: Sprite2D, boss_collision: bool)
signal stopped
signal moved

func _ready() -> void:
	position = map_to_tilemap(position)
	old_pos = Vector2(position)

func _process(delta: float) -> void:
	if not ignore_player_input:
		var dirx := Input.get_axis("Left", "Right")
		var diry := Input.get_axis("Up", "Down")
		move(dirx, diry)
			
	update_movement(delta)
	
	if not is_stopped() and message_window.visible:
		message_window.disappear()
		
#region Movement
		
# Request movement in the direction of (dirx, diry) vector
func move(dirx: float, diry: float) -> void:
	dirx = signf(dirx)
	diry = signf(diry)
	next_speed = Vector2(
		# Basically, if the player wants to move horizontally and vertically,
		# set xspeed to horizontal direction * 2 (-2 if left and 2 if right),
		# otherwise the player shouldn't move (only horizontal moves are not allowed)
		(dirx * 2 if diry else 0.0),
		# If the player wants to move diagonally, set yspeed to vertical direction,
		# (-1 if up and 1 is down), otherwise we move only vertically with
		# absolute yspeed 2
		(diry if dirx else diry * 2)
		)
	if next_speed.length() > 0:
		moved_at_all = true
		
# When the movement should be stopped
func stop_conditions() -> void:
	var next_piece := get_next_cell_piece()
	
	# Too many steps
	if board.selected_piece and playing_levels.size() >= board.selected_piece.steps:
		if next_cell_exists() and not message_window.visible:
			message_window.appear("Unable to advance farther.", false)
			board.adjust_message_pos()
		stop()
	# Piece collision
	elif board.selected_piece and next_piece:
		piece_collision.emit(next_piece, not next_piece.is_player())
		stop()
		if not next_piece.is_player():
			set_process(false)
	# The next cell is empty
	elif not next_cell_exists() and \
		(movement_style == MovementStyle.ONLY_INSIDE_CELLS or board.selected_piece):
			stop()
	# The next cell is outside the camera limits
	elif movement_style == MovementStyle.OUTSIDE_CELLS:
		var next_cell := get_next_cell_pos()
		var xlimit: int = $Camera2D.limit_right / 32 - 2
		var ylimit: int = $Camera2D.limit_bottom / 32 - 2
		if next_cell.x < 0 or next_cell.y < next_cell.x % 2 \
			or next_cell.x > xlimit or next_cell.y > ylimit:
			stop()
	
func update_movement(delta: float) -> void:
	if is_stopped():
		# Save the current cell position
		old_pos = Vector2(position)
		# If is stopped and movement is requested, move..
		speed = next_speed
		
		if board.selected_piece and board.selected_piece.is_player() \
		and moved_at_all and is_stopped():
			for boss: Node2D in board.get_boss_pieces():
				if boss.position.distance_to(position) < 36:
					piece_collision.emit(boss, true)
					moved_at_all = false
					return
		
		# ..but be aware of things that should stop the movement
		if not is_stopped():
			stop_conditions()
		elif board.selected_piece \
			and message_window.state == message_window.State.SHOWN \
			and message_window.get_text() == "Unable to advance farther.":
				message_window.disappear()
	else:
		# If we're moving and then we moved onto the next hex
		var yoffset := 32 if not speed.x else 16
		if (speed.y > 0 and position.y > old_pos.y + yoffset - speed.y) \
		or (speed.y < 0 and position.y < old_pos.y - yoffset - speed.y):
			moved.emit()
			# Save the current cell position
			old_pos = Vector2(position)
			# If we're moving in different direction than
			# the current requested move, stop and move in
			# the requested direction
			if next_speed != speed:
				stop()
				speed = next_speed
			
			# Save the level from the current hex
			if board.selected_piece:
				playing_levels.append(get_level_id(get_current_cell()))
				
			# If we're still requesting for movement, be aware
			# of things that should stop the movement
			if next_speed != Vector2.ZERO:
				stop_conditions()
			
	position.x += speed.x * 60 * delta
	position.y += speed.y * 60 * delta

func is_stopped() -> bool:
	return absf(speed.x) < 0.01 && absf(speed.y) < 0.01

func stop() -> void:
	speed = Vector2i.ZERO
	next_speed = Vector2i.ZERO
	position = map_to_tilemap(position)
	stopped.emit()
	
#endregion

#region Tilemap-related code

# Snap coords to tilemap cells
func map_to_tilemap(pos: Vector2, tm: TileMapLayer = tilemap) -> Vector2:
	return tm.map_to_local(tm.local_to_map(pos)) - Vector2(0, 7)
	
# Convert local coords into tilemap cell coords
func get_cell_pos(pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(pos)
	
# Get cell from the position
func cell_from_pos(pos: Vector2i) -> Vector2i:
	return tilemap.get_cell_atlas_coords(pos)
	
# Check if a cell exists
func cell_exists(pos: Vector2i) -> bool:
	return board_outline.get_cell_atlas_coords(pos).x >= 0
	
func get_next_cell_pos() -> Vector2i:
	var next_pos := Vector2(old_pos)
	next_pos += Vector2(speed) * 16
	return get_cell_pos(next_pos)

func next_cell_exists() -> bool:
	return cell_exists(get_next_cell_pos())
	
func get_current_cell() -> Vector2i:
	return cell_from_pos(get_cell_pos(old_pos))
	
#endregion

func reset_playing_levels() -> void:
	playing_levels.clear()

func get_level_id(tile: Vector2i) -> int:
	return tile.x + tile.y * 5
	
# Get the piece (if exists) from the next cell
func get_next_cell_piece() -> Sprite2D:
	for p: Sprite2D in board.get_board_pieces():
		if p.get_cell_pos() == get_next_cell_pos():
			return p
	return null
