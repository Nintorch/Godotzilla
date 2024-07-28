@tool
extends Sprite2D

const PIECE_STEPS := [
	2, # Godzilla
	4, # Mothra
]
const FRAME_COUNT := 3  # White piece and 2 colored walking sprites
const FRAME_SPEED := [
	0.13, # Godzilla
	0.2, # Mothra
]

@export var piece_character := GameCharacter.Type.GODZILLA:
	set(value):
		piece_character = value
		update_frame()
		queue_redraw()
@export_enum("Player", "Boss") var piece_type := 0:
	set(value):
		piece_type = value
		update_frame()
		queue_redraw()
@export var boss_scene: PackedScene = null
## Only works if it's a boss, otherwise loaded from the current save.
## If there's no current save, then it's 1.
@export var level := 1

# "Board Pieces" node
@onready var parent = get_parent()

var tilemap: TileMapLayer
var selector: Node2D

var init_pos
var piece_frame := 0
var tile_below := Vector2i(-1, -1)
var selected = false
var steps := 0
var walk_frame := 0.0
var walk_anim := 0

var character_data = {
	hp = 0.0,
	bars = 0,
	xp = 0,
	level = 1,
}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	await Global.get_current_scene().ready
	selector = $"../../Selector"
	tilemap = selector.tilemap
	process_priority = 1
	
	# Adjust position
	position = selector.map_to_tilemap(position, tilemap)
	init_pos = position
	update_frame()
	
	await get_tree().process_frame
	hide_cell_below()
	
	if piece_character == GameCharacter.Type.MOTHRA:
		walk_anim = 1
	
	var player_level = Global.get_current_scene().board_data.player_level
	if piece_character in player_level:
		level = player_level[piece_character]
	steps = PIECE_STEPS[piece_character]
	character_data.bars = \
		GameCharacter.calculate_bar_count(piece_character, level)
	character_data.hp = character_data.bars * 8

func _process(delta: float) -> void:
	if selected:
		global_position = selector.global_position
		
		if walk_anim == 0 and not selector.is_stopped() \
			or walk_anim == 1:
				# Switch frame every 0.2 of a second
				walk_frame += delta / FRAME_SPEED[piece_character]
				if walk_frame >= 2:
					walk_frame -= 2
				piece_frame = floori(1 + walk_frame)
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
	tilemap.erase_cell(get_cell_pos())
	
func show_cell_below() -> void:
	tilemap.set_cell(get_cell_pos(), 1, tile_below)
	tile_below = Vector2i(-1, -1)

func select() -> void:
	selected = true
	
	piece_frame = 1
	walk_frame = 0.0
	update_frame()
	
	selector.visible = false
	# Just in case, but mostly for bosses
	selector.global_position = global_position
	show_cell_below()
	# Move this piece above all other pieces
	parent.move_child(self, -1)
	
	Global.board.menubip.play()
	
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
	
func remove() -> void:
	if Global.board.selected_piece == self:
		Global.board.selected_piece = null
	selector.visible = true
	show_cell_below()
	queue_free()
	
func is_player() -> bool:
	return piece_type == 0
	
func get_nav_agent() -> NavigationAgent2D:
	return $NavigationAgent2D
	
func get_character_name() -> String:
	return GameCharacter.CHARACTER_NAMES[piece_character]
