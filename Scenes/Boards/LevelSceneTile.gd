class_name LevelSceneTile extends Sprite2D

@export var level: PackedScene
@export var level_variation: LevelVariation
## Check if the selector is currently over a transition level tile, a.k.a. a level
## after which a board piece should be sent to the next planet
@export var transition_level: bool

func get_level(tilemap: TileMapLayer, cell_pos: Vector2i) -> PackedScene:
	if level != null:
		return level
	elif level_variation != null:
		return level_variation.get_level(tilemap, cell_pos)
	
	return null
