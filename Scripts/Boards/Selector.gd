extends Sprite2D

enum MovementStyle {
	OUTSIDE_CELLS,
	ONLY_INSIDE_CELLS,
}

@export var movement_style = MovementStyle.OUTSIDE_CELLS

@onready var tilemap: TileMap = get_parent()
@onready var message_window = $"../../CanvasLayer/MessageWindow"
@onready var board = $"../../.."

# Speed (in pixels per frame for 60 fps)
var speed: Vector2i = Vector2i(0, 0)
# Current cell position in pixels
var old_pos: Vector2

var playing_levels: Array[int] = []

func _ready():
	position = map_to_tilemap(position)
	old_pos = Vector2(position)

func _process(delta: float):
	if is_stopped():
		next_hex()
	else:
		var yoffset = 32 if not speed.x else 16
		if speed.y > 0 and position.y > old_pos.y + yoffset - speed.y:
			adjust_pos()
			next_hex()
		if speed.y < 0 and position.y < old_pos.y - yoffset - speed.y:
			adjust_pos()
			next_hex()
			
	position.x += speed.x * 60 * delta
	position.y += speed.y * 60 * delta
	
	if not is_stopped() and message_window.visible:
		message_window.disappear()
			
func is_stopped():
	return speed == Vector2i.ZERO

func stop():
	speed.x = 0
	speed.y = 0
	
func map_to_tilemap(pos: Vector2, tm: TileMap = tilemap) -> Vector2:
	return tm.map_to_local(tm.local_to_map(pos)) - Vector2(0, 7)

func adjust_pos():
	position = map_to_tilemap(position)
	old_pos = Vector2(position)
	
	if board.selected_piece:
		playing_levels.append(get_level_id(get_current_cell()))
	
func next_hex():
	var dirx = Input.get_axis("Left", "Right")
	var diry = Input.get_axis("Up", "Down")
	
	# Basically, if the player wants to move horizontally and vertically,
	# set xspeed to horizontal direction * 2 (-2 if left and 2 if right),
	# otherwise the player shouldn't move (only horizontal moves are not allowed)
	speed.x = roundi(dirx * 2) if diry else 0
	# If the player wants to move diagonally, set yspeed to vertical direction,
	# (-1 if up and 1 is down), otherwise we move only vertically with
	# absolute yspeed 2
	speed.y = roundi(diry) if dirx else roundi(diry * 2)
	
	# Stop if no input
	if not diry:
		stop()
		if board.selected_piece \
			and message_window.state == message_window.State.SHOWN \
			and message_window.get_text() == "Unable to advance farther.":
			message_window.disappear()
	# Too many steps
	elif board.selected_piece and playing_levels.size() >= board.selected_piece.steps:
		if get_next_cell().x >= 0 and not message_window.visible:
			message_window.appear("Unable to advance farther.", false)
			board.adjust_message_pos()
		stop()
	# Stop if next cell is empty
	elif movement_style == MovementStyle.ONLY_INSIDE_CELLS and get_next_cell().x < 0 \
		or board.selected_piece and get_next_cell().x < 0:
		stop()
	# Stop if next cell is outside the camera limits
	elif movement_style == MovementStyle.OUTSIDE_CELLS:
		var next_cell = get_next_cell_pos()
		var xlimit: int = $Camera2D.limit_right / 32 - 2
		var ylimit: int = $Camera2D.limit_bottom / 32 - 2
		if next_cell.x < 0 or next_cell.y < next_cell.x % 2 \
			or next_cell.x > xlimit or next_cell.y > ylimit:
			stop()
	
func get_cell_pos(pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(pos)
	
func cell_from_pos(pos: Vector2i) -> Vector2i:
	return tilemap.get_cell_atlas_coords(1, pos)
	
func cell_exists(pos: Vector2i) -> Vector2i:
	return tilemap.get_cell_atlas_coords(0, pos)
	
func get_next_cell_pos() -> Vector2i:
	var next_pos = Vector2(old_pos)
	next_pos += Vector2(speed) * 16
	return get_cell_pos(next_pos)

func get_next_cell() -> Vector2i:
	return cell_exists(get_next_cell_pos())
	
func get_current_cell() -> Vector2i:
	return cell_from_pos(get_cell_pos(old_pos))

func reset_playing_levels() -> void:
	playing_levels.clear()

func get_level_id(tile: Vector2i) -> int:
	return tile.x + tile.y * 5 - 1
