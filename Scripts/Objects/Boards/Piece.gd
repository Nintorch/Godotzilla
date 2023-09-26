@tool
extends Sprite2D

@export var piece_character := GameCharacter.Type.GODZILLA
@export_enum("Player", "Boss") var piece_type := 0

const PIECE_STEPS = [
	2, # Godzilla
	4, # Mothra
]
const FRAME_COUNT = 3  # White piece and 2 colored walking sprites

var tilemap: TileMap
var selector

var init_pos
var piece_frame := 0
var walk_frame := 0.0
var tile_below := Vector2i(-1, -1)
var selected = false
var steps := 0

var character_name := GameCharacter.CharacterNames[piece_character]
var hp := 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	tilemap = $"../.."
	selector = $"../../Selector"
	
	# Adjust position
	position = selector.map_to_tilemap(position, tilemap)
	init_pos = position
	
	steps = PIECE_STEPS[piece_character]
	update_frame()
	
	await get_tree().process_frame
	hide_cell_below()

func _process(delta: float) -> void:
	if selected:
		global_position = selector.global_position
		
		match piece_character:
			GameCharacter.Type.GODZILLA:
				if not selector.is_stopped():
					# Switch frame every 0.2 of a second
					walk_frame += delta / 0.2
					if walk_frame >= 2:
						walk_frame -= 2
					piece_frame = 1 + walk_frame
					update_frame()

func update_frame() -> void:
	# + 1 to skip the top row of the spritesheet (non-character sprites for boards)
	var value = (piece_character + 1) * FRAME_COUNT + piece_frame
	if value < (hframes * vframes):
		frame = value
	
	# Face the left direction if it's a boss
	scale.x = 1 if piece_type == 0 else -1

func get_cell_pos() -> Vector2i:
	if Engine.is_editor_hint():
		return Vector2i.ZERO
	return selector.get_cell_pos(position)

func hide_cell_below() -> void:
	if Engine.is_editor_hint():
		return
	var tile = selector.cell_from_pos(get_cell_pos())
	if tile.x < 0: # Return if already hidden
		return
	tile_below = tile
	tilemap.erase_cell(1, get_cell_pos())
	
func show_cell_below() -> void:
	tilemap.set_cell(1, get_cell_pos(), 0, tile_below)
	tile_below = Vector2i(-1, -1)

func select() -> void:
	selected = true
	
	piece_frame = 1
	walk_frame = 0.0
	update_frame()
	
	selector.visible = false
	show_cell_below()
	
func deselect() -> void:
	selected = false
	
	piece_frame = 0
	update_frame()
	
	selector.visible = true
	selector.reset_playing_levels()
	
	position = init_pos
	hide_cell_below()
	
func prepare_start() -> void:
	init_pos = position
	selected = false
	
	piece_frame = 0
	update_frame()
	
	hide_cell_below()
	
# Called after prepare_start()
func remove() -> void:
	selector.visible = true
	show_cell_below()
	queue_free()
	
func is_player() -> bool:
	return piece_type == 0
