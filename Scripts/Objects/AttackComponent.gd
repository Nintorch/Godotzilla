class_name AttackComponent
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
@export var default_hitbox: CollisionShape2D

@onready var area_2d: Area2D = $Area2D
@onready var hitboxes: Node = self

# We don't want to attack a body multiple times in the same attack
var attacked_bodies: Array[Node2D] = []

signal attacked(body: Node2D, amount: float)

func _ready() -> void:
	for node: CollisionShape2D in get_children().filter(
		func(c: Node) -> bool: return c is CollisionShape2D):
				node.set_deferred("disabled", true)
	if default_hitbox != null:
		set_hitbox_node(default_hitbox.duplicate(), default_hitbox.position)
	if not attack_always:
		attack_bodies()
		area_2d.body_entered.connect(_on_area_2d_body_entered)
	
func _process(_delta: float) -> void:
	if attack_always:
		attack_bodies()

func attack_bodies(amount := default_attack_amount, hurt_time := default_hurt_time) -> void:
	var bodies := area_2d.get_overlapping_bodies()
	for body in bodies:
		attack_body(body, amount, hurt_time)
			
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
	set_hitbox_node(null, Vector2.ZERO)
	
#region Hitbox

func set_hitbox_node(hitbox: CollisionShape2D, offset: Vector2) -> void:
	area_2d.get_children().map(func(c: Node) -> void: c.queue_free())
	if hitbox != null:
		area_2d.add_child(hitbox)
		hitbox.visible = true
		hitbox.position = offset
		
func set_hitbox_template(template_name: String) -> void:
	var hitbox := hitboxes.get_node(template_name) as CollisionShape2D
	if hitbox == null:
		printerr("Invalid hitbox: " + template_name)
		return
		
	set_hitbox_node(hitbox.duplicate(), hitbox.position)
	
func set_hitbox(size: Vector2, offset: Vector2) -> void:
	var hitbox := CollisionShape2D.new()
	hitbox.shape = RectangleShape2D.new()
	hitbox.shape.size = size
	set_hitbox_node(hitbox, offset)
	
# Compatibility method
func set_collision(size: Vector2, offset: Vector2) -> void:
	set_hitbox(size, offset)
	
#endregion

func _on_area_2d_body_entered(body: Node2D) -> void:
	attack_body(body)
