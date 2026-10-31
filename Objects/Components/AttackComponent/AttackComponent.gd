class_name AttackComponent extends Node2D

## Simple attacks will use this node to play its animations
@export var attack_animation_player: AnimationPlayer
## A node that has attack hitboxes as its children
@export var hitboxes: Node
@export var enemy := false
## The name of the attack that should play when the component is ready
@export var initial_attack: String
@export var attacks: Array[AttackDescription]
@export var objects_to_ignore: Array[Node2D]
@export_group("Advanced Attacks")
## If an attack is of advanced type, it will call its specified function on this node
@export var attack_function_node: Node

@export_group("Attack By Touching", "touch_damage_")
@export var touch_damage_enable := false
@export var touch_damage_amount := 0.0
@export var touch_damage_hitbox: CollisionShape2D:
	set(value):
		if value == touch_damage_hitbox:
			return
		touch_damage_hitbox = value
		if not is_inside_tree():
			return
		for node in touch_damage_area.get_children():
			node.queue_free()
		touch_damage_area.add_child(touch_damage_hitbox.duplicate())

@onready var area_2d: Area2D = $Area2D
@onready var touch_damage_area: Area2D = $TouchDamageArea
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var current_attack: AttackDescription = null
var variation := false
# We don't want to attack a body multiple times in the same attack
var attacked_bodies: Array[Node2D] = []

## Happens when the attack component touches an attackable body
signal touched_body(body: Node2D)
## Happens when the attack component attacks a body
signal attacked(body: Node2D, attack: AttackDescription)
## Happens before an attack starts
signal attack_started(attack: AttackDescription)
## Happens after an attack finishes
signal attack_finished(attack: AttackDescription)

func _ready() -> void:
	if get_child_count() == 0:
		push_warning("Attack component for " + str(get_parent()) + " was NOT instanced"
			+ " by using its scene file, so it can't access its internal nodes.")
	
	if initial_attack != "":
		start_attack(initial_attack)
		
	if touch_damage_enable:
		touch_damage_area.add_child(touch_damage_hitbox.duplicate())

	if touch_damage_enable:
		var bodies := touch_damage_area.get_overlapping_bodies()
		for body in bodies:
			attack_body(body, null, touch_damage_amount, false)
	
	if (current_attack != null
		and current_attack.type != AttackDescription.Type.ONE_TIME):
			attack_bodies()
	
## Start an attack with the specified name. Returns true if
## the attack was finished successfully (haven't been stopped early by request)
func start_attack(attack_name: String) -> bool:
	# An attack is still playing
	if current_attack != null:
		await stop_attack()
		
	# Find the attack description
	for attack_desc in attacks:
		if attack_desc.name == attack_name:
			current_attack = attack_desc
			break
	if current_attack == null:
		printerr("Unknown attack: " + attack_name)
		return false
		
	attack_started.emit(current_attack)
	
	var result := false
	
	if current_attack.simple_or_advanced == 0:
		result = await _start_simple_attack()
	elif current_attack.simple_or_advanced == 1:
		await attack_function_node.call(current_attack.function_name)
		if is_attacking():
			result = true
			stop_attack()
	else:
		attack_function_node.call(current_attack.function_name)
		result = await _start_simple_attack()
	return result
	
func _start_simple_attack() -> bool:
	var result := false
	await _simple_attack()
	if is_attacking():
		result = true
		if current_attack.type != AttackDescription.Type.LASTS_FOREVER:
			stop_attack()
	return result
	
func _simple_attack_play_sfx() -> void:
	if is_instance_valid(current_attack.sfx):
		if current_attack.sfx_offset > 0:
			await get_tree().create_timer(current_attack.sfx_offset, false).timeout
		sfx_player.stream = current_attack.sfx
		sfx_player.volume_db = current_attack.sfx_db
		sfx_player.play()
		
func _simple_attack_repeat_animation(animation_player: AnimationPlayer, repeat_times: int) -> void:
	var animation_name := animation_player.current_animation
	await animation_player.animation_finished
	for i in repeat_times - 1:
		await get_tree().process_frame # Just why is it required???
		if not is_instance_valid(animation_player): return
		animation_player.play(animation_name)
		await animation_player.animation_finished
		
func _simple_attack() -> void:
	if current_attack == null:
		return
		
	if current_attack.damage_amount < 0.0 or is_zero_approx(current_attack.damage_amount):
		push_warning("Bug: Attack damage amount is 0 or negative, so no one will get hurt")
		
	_simple_attack_play_sfx()
		
	var animation_player := attack_animation_player
	if not current_attack.animation_player.is_empty():
		animation_player = get_node(current_attack.animation_player)
	
	if (current_attack.reset_animation_before
		and is_instance_valid(animation_player)
		and animation_player.has_animation("RESET")):
			animation_player.play("RESET")
			
	if get_tree() == null: # Prevents a rare crash
		return
		
	await get_tree().process_frame
	if not is_attacking(): return # Just in case
	
	if current_attack.animation_name != "" and current_attack.animation_name2 != "":
		variation = not variation
		animation_player.play(current_attack.animation_name if variation
			else current_attack.animation_name2)
	elif current_attack.animation_name != "":
		animation_player.play(current_attack.animation_name)
	elif (current_attack.time_length < 0.0
		and current_attack.type != AttackDescription.Type.LASTS_FOREVER):
			printerr("No attack animation was assigned to attack " + current_attack.name +
				" but the Time Length property is still negative.")
			return
	
	if current_attack.start_time_offset > 0.0:
		await get_tree().create_timer(current_attack.start_time_offset, false).timeout
		if not is_attacking(): return
	
	if current_attack.hitbox_name != "":
		set_hitbox_template(current_attack.hitbox_name)
		
	if not current_attack.hitbox_node.is_empty():
		var node: CollisionShape2D = get_node(current_attack.hitbox_node)
		set_hitbox_node(node.duplicate(), node.position)
		
	# Not sure why I have to wait 3 frames for it to work
	if current_attack.type == AttackDescription.Type.ONE_TIME:
		for i in 3:
			await get_tree().process_frame
			
		if not is_attacking(): return
		attack_bodies()
		
	if current_attack and current_attack.type != AttackDescription.Type.LASTS_FOREVER:
		if current_attack.time_length < 0.0:
			await _simple_attack_repeat_animation(animation_player, current_attack.animation_repeat_times)
		else:
			await get_tree().create_timer(current_attack.time_length, false).timeout
	# if not is_attacking(): return
		
func stop_attack() -> void:
	if current_attack == null:
		return
	var save_attack := current_attack
	var animation_player := attack_animation_player
	if not current_attack.animation_player.is_empty():
		animation_player = get_node(current_attack.animation_player)
	current_attack = null
	attack_finished.emit(save_attack)
	set_hitbox_node(null, Vector2.ZERO)
	attacked_bodies = []
	if ((save_attack.simple_or_advanced == 0 or save_attack.simple_or_advanced == 2)
		and save_attack.reset_animation_after
		and is_instance_valid(animation_player)
		and animation_player.has_animation("RESET")):
			animation_player.play("RESET")
	
func attack_bodies() -> void:
	if current_attack == null:
		return
		
	var bodies := area_2d.get_overlapping_bodies()
	for body in bodies:
		attack_body(body, current_attack)
			
func attack_body(
	body: Node2D,
	attack: AttackDescription,
	amount: float = 0.0,
	add_to_attacked := true) -> void:
	if (body == get_parent()
		or body in objects_to_ignore
		or body in attacked_bodies
		or not body.has_node("HealthComponent")):
			return
	var hc: HealthComponent = body.get_node("HealthComponent")
	if enemy == hc.enemy:
		return
	touched_body.emit(body)
	if not hc.is_hurtable():
		return
	if attack != null:
		hc.damage(attack, -1, get_parent())
	else:
		hc.damage_amount(amount, get_parent())
	attacked.emit(body, attack)
	if add_to_attacked:
		attacked_bodies.append(body)
			
func is_attacking() -> bool:
	return current_attack != null
	
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
	
## DEPRECATED: Compatibility method
func set_collision(size: Vector2, offset: Vector2) -> void:
	set_hitbox(size, offset)
	
#endregion
