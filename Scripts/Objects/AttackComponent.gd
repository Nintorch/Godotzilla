extends Node2D

## Always keep checking for other bodies in the attack component and attack them
@export var attack_always := false
@export var default_attack_amount := 4.0
@export var default_hurt_time := -1.0
@export var objects_to_ignore: Array[Node2D]
## Allow the attack component to attack at all
@export var should_attack := true
## Set to true if this attack component belongs to an enemy,
## otherwise false if it belongs to a player/not enemy
@export var enemy := false

@onready var area_2d: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

# We don't want to attack a body multiple times in the same attack
var attacked_bodies: Array[Node2D] = []

signal attacked(body: Node2D, amount: float)

func _ready() -> void:
	collision.shape = collision.shape.duplicate()
	collision.shape.size = Vector2.ZERO
	if not attack_always:
		attack_bodies()
		area_2d.body_entered.connect(_on_area_2d_body_entered)
	
func _process(_delta: float) -> void:
	if attack_always:
		attack_bodies()

func attack_bodies(amount := default_attack_amount, hurt_time := default_hurt_time) -> void:
	var bodies := area_2d.get_overlapping_bodies()
	for body in bodies:
		attack_body(body, amount)
			
func attack_body(body: Node2D,
				amount := default_attack_amount,
				hurt_time := default_hurt_time) -> void:
	if body == get_parent() or body in objects_to_ignore or not should_attack:
		return
	if body.has_node("HealthComponent") and (enemy != body.get_node("HealthComponent").enemy) \
		and body not in attacked_bodies:
			body.get_node("HealthComponent").damage(amount, hurt_time)
			attacked.emit(body, amount)
			attacked_bodies.append(body)

func set_collision(size: Vector2, offset: Vector2) -> void:
	collision.shape.size = size
	collision.position = offset
	
# The next 2 functions are useful for attack moves of a player or a boss
	
func start_attack(amount: float, hurt_time := -1.0) -> void:
	attack_always = true
	should_attack = true
	default_attack_amount = amount
	default_hurt_time = hurt_time
	attacked_bodies.clear()
	
func stop_attack() -> void:
	attack_always = false
	should_attack = false
	attacked_bodies.clear()
	collision.shape.size = Vector2.ZERO
	collision.position = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	attack_body(body)
