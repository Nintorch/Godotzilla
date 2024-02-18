extends Node2D

@export var attack_always := false
@export var default_attack_amount := 4
@export var objects_to_ignore: Array[Node2D]

@onready var area_2d: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	collision.shape = collision.shape.duplicate()
	if not attack_always:
		attack_bodies()
		area_2d.body_entered.connect(_on_area_2d_body_entered)
	
func _process(delta: float) -> void:
	if attack_always:
		attack_bodies()

func attack_bodies(amount: float = default_attack_amount) -> void:
	var bodies := area_2d.get_overlapping_bodies()
	for body in bodies:
		attack_body(body, amount)
			
func attack_body(body: Node2D, amount: float = default_attack_amount) -> void:
	if body == get_parent() or body in objects_to_ignore:
		return
	if body.has_node("HealthComponent"):
		body.get_node("HealthComponent").damage(amount)

func set_collision(size: Vector2, offset: Vector2) -> void:
	collision.shape.size = size
	collision.position = offset

func _on_area_2d_body_entered(body: Node2D) -> void:
	attack_body(body)
