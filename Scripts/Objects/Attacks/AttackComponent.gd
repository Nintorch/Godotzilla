class_name AttackComponent
extends Node2D

@export var attack_animation_player: AnimationPlayer
## A node that has attack hitboxes as its children
@export var hitboxes: Node
@export var enemy := false
@export var attacks: Array[AttackDescription]
@export var objects_to_ignore: Array[Node2D]

@onready var area_2d: Area2D = $Area2D

var current_attack: AttackDescription = null
var variation := false
# We don't want to attack a body multiple times in the same attack
var attacked_bodies: Array[Node2D] = []
var attack_started := false

signal body_attacked(body: Node2D, attack: AttackDescription)
# DEPRECATED: Signal for compatibility reasons
signal attacked(body: Node2D, amount: float)

func _process(delta: float) -> void:
	if (current_attack != null
		and current_attack.type == AttackDescription.Type.CONTINUOUS):
			attack_bodies()
	
func start_attack(attack_name: String) -> void:
	# Find the attack description
	current_attack = null
	for attack_desc in attacks:
		if attack_desc.name == attack_name:
			current_attack = attack_desc
			break
	if current_attack == null:
		printerr("Unknown attack: " + attack_name)
		return
	
	if current_attack.animation_name != "" and current_attack.animation_name2 != "":
		variation = not variation
		attack_animation_player.play(current_attack.animation_name if variation
			else current_attack.animation_name2)
	elif current_attack.animation_name != "":
		attack_animation_player.play(current_attack.animation_name)
	elif current_attack.time_length < 0.0:
		printerr("No attack animation was assigned to attack " + attack_name +
			" but the Time Length property is still negative.")
		return
		
	if current_attack.start_time_offset <= 0.0:
		attack_started = true
	else:
		await get_tree().create_timer(current_attack.start_time_offset, false).timeout
		# The attack could've been requested to be stopped by now
		# (For example, the player could've been hit)
		if current_attack != null:
			attack_started = true
		else:
			printerr("The attack has been stopped after an await in AttackComponent.gd")
			return
	
	if current_attack.hitbox_name != "":
		set_hitbox_template(current_attack.hitbox_name)
		
	# Not sure why I have to wait 2 frames for it to work
	if current_attack.type == AttackDescription.Type.ONE_TIME:
		await get_tree().process_frame
		await get_tree().process_frame
		attack_bodies()
	else:
		if current_attack.time_length < 0.0:
			await attack_animation_player.animation_finished
		else:
			await get_tree().create_timer(current_attack.time_length, false).timeout
	
	stop_attack()
	
func stop_attack() -> void:
	current_attack = null
	set_hitbox_node(null, Vector2.ZERO)
	attacked_bodies = []
	
func attack_bodies() -> void:
	var bodies := area_2d.get_overlapping_bodies()
	for body in bodies:
		attack_body(body)
			
func attack_body(body: Node2D) -> void:
	if body == get_parent() or body in objects_to_ignore:
		return
	if body.has_node("HealthComponent") and (enemy != body.get_node("HealthComponent").enemy) \
		and body not in attacked_bodies:
			body.get_node("HealthComponent").damage(
				current_attack.damage_amount, current_attack.hurt_time
				)
			attacked.emit(body, current_attack.damage_amount)
			body_attacked.emit(body, current_attack)
			attacked_bodies.append(body)
	
#region Hitbox

func set_hitbox_node(hitbox: CollisionShape2D, offset: Vector2) -> void:
	# Destroy all collision shapes inside the Area2D
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
	
# DEPRECATED: Compatibility method
func set_collision(size: Vector2, offset: Vector2) -> void:
	set_hitbox(size, offset)
	
#endregion
