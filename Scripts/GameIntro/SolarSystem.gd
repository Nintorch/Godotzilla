extends Node2D

@onready var solar_system_object: Sprite2D = $Image
@onready var planet_move_timer: Timer = $PlanetMoveTimer

var solar_system_image := Image.load_from_file("res://Sprites/GameIntro/images.png")
var planets: Array[Node2D] = []

func _ready() -> void:
	planets.assign(get_children().filter(func(p: Node):
		return p.name != "Image" and p is Sprite2D))

func move_planets() -> void:
	for planet in planets:
		planet.position.x += 1
		
		var image_pos: Vector2 = solar_system_object.to_local(planet.global_position)
		var color := solar_system_image.get_pixel(image_pos.x, image_pos.y)
		if color.g > 0.0:
			continue
		if solar_system_image.get_pixel(image_pos.x, image_pos.y-1).g > 0.0:
			planet.position.y -= 1
		elif solar_system_image.get_pixel(image_pos.x, image_pos.y+1).g > 0.0:
			planet.position.y += 1
