class_name AttackComponent
extends Node2D

@export var attack_animation_player: AnimationPlayer
@export var attacks: Array[AttackDescription]
## A node that has attack hitboxes as its children
@export var hitboxes: Node
@export var objects_to_ignore: Array[Node2D]
@export var enemy := false

var current_attack: AttackDescription = null
var variation := false
# We don't want to attack a body multiple times in the same attack
var attacked_bodies: Array[Node2D] = []
var attack_started := false

signal attacked(body: Node2D, amount: float)
	
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
	
	set_hitbox_template(current_attack.hitbox_name)
	
	if current_attack.start_time_offset <= 0.0:
		attack_started = true
	else:
		get_tree().create_timer(current_attack.start_time_offset).timeout.connect(func() -> void:
			# The attack could've been requested to be stopped by now
			# (For example, the player could've been hit)
			if current_attack != null:
				attack_started = true
			)
	
func stop_attack() -> void:
	current_attack = null
	
#region Hitbox

func set_hitbox_node(hitbox: CollisionShape2D, offset: Vector2) -> void:
	pass
		
func set_hitbox_template(template_name: String) -> void:
	pass
	
func set_hitbox(size: Vector2, offset: Vector2) -> void:
	pass
	
# Compatibility method
func set_collision(size: Vector2, offset: Vector2) -> void:
	set_hitbox(size, offset)
	
#endregion
