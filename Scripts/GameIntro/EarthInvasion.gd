extends Node2D

const SMALL_SHIPS_SPEED := 0.0625 * 60
const BIG_SHIPS_SPEED := 0.125 * 60

@onready var ships: Node2D = $Ships

var small_ships: Array[Sprite2D] = []
var big_ships: Array[Sprite2D] = []

func _ready() -> void:
	small_ships.assign(ships.get_children().filter(func(node: Node) -> bool:
		return node is Sprite2D and node.name.begins_with("Small")
		))
	big_ships.assign(ships.get_children().filter(func(node: Node) -> bool:
		return node is Sprite2D and node.name.begins_with("Big")
		))

func _process(delta: float) -> void:
	for ship in small_ships:
		move_ship(ship, SMALL_SHIPS_SPEED, delta)
	for ship in big_ships:
		move_ship(ship, BIG_SHIPS_SPEED, delta)
	
func move_ship(ship: Sprite2D, speed: float, delta: float) -> void:
	ship.position.x -= speed * delta
	if (ship.position.x + ship.region_rect.size.x / 2) < 0:
		ship.position.x += 256 + ship.region_rect.size.x
