class_name LevelVariation
extends Resource

@export var levels: Array[PackedScene]

func get_level(tilemap: TileMapLayer, cell_pos: Vector2i) -> PackedScene:
	var id: int = cell_pos.x + tilemap.get_used_rect().size.x * cell_pos.y
	return levels[id % levels.size()]
