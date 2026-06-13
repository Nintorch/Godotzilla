class_name HealthComponent extends Node

## Maximum value of health the component should hold
@export var max_value := 10.0
@export var enemy := false
## The amount of time in seconds the component should be invincible after getting damaged
@export var invincibility_time_seconds := 0.0
## How many health points should be taken each frame.
## Put 0.0, if you want the HP value to be immediately set the target value
## without any smoothing.
@export var health_speed := 0.0
@export var damage_coefficient := 1.0

## The current amount of health
var target_value := 0.0
## The amount of health that should be shown on screen.
## If you want to change the amount of health, use "target_value" property
var value := 0.0:
	set(v):
		value = v
		value_changed.emit(value)
var died := false
var invincible := false
var attacker_body: Node = null

## The health amount that should be shown on screen has changed
signal value_changed(new_value: float)
signal damaged(amount: float, attack: AttackDescription)
signal healed(amount: float)
## Happens when the maximum amount of health changes
signal resized(new_amount: float)
## Happens when the health value reaches 0
signal dead

signal invincibility_started
signal invincibility_ended

func _ready() -> void:
	set_value(max_value)
	
func _process(delta: float) -> void:
	if health_speed > 0.0:
		value = move_toward(value, target_value, health_speed * 60 * delta)
	else:
		value = target_value
	if value <= 0.0 and not died:
		died = true
		dead.emit()

## Make the health component decrease the health amount through an attack or
## by specifying the damage amount. Additionally, damaging the health component
## will start the invincibility timer, if the invincibility time was specified.
## If you don't have an AttackDescription object, pass null as the first argument.
func damage(attack: AttackDescription, amount := -1.0, attacker: Node = null) -> void:
	var attack_damage := amount * damage_coefficient
	var invincibility_time := invincibility_time_seconds
	if attack != null:
		attack_damage = attack.damage_amount * damage_coefficient
		if attack.invincibility_time >= 0:
			invincibility_time = attack.invincibility_time
	if (attack_damage <= 0 and damage_coefficient > 0) or not is_hurtable():
		return
	
	attacker_body = attacker
	target_value = clampf(target_value - attack_damage, 0.0, max_value)
	if target_value > 0.0 or health_speed > 0.0:
		damaged.emit(attack_damage, attack)
	if invincibility_time > 0.0:
		invincible = true
		invincibility_started.emit()
		
		await get_tree().create_timer(invincibility_time_seconds, false).timeout
		
		invincible = false
		invincibility_ended.emit()
		
## Convenience method for calling damage(null, the_amount_specified_here)
func damage_amount(amount: float, attacker: Node = null) -> void:
	damage(null, amount, attacker)
		
func heal(amount: float) -> void:
	if amount <= 0 or target_value >= max_value or died:
		return
		
	if target_value + amount <= max_value:
		target_value += amount
		healed.emit(amount)
	else:
		var old_value := target_value
		target_value = max_value
		healed.emit(max_value - old_value)
		
## Set the health value to its maximum value
func fill() -> void:
	set_value(max_value)
		
## Change the maximum value of health
func resize(new_hp_amount: float) -> void:
	max_value = new_hp_amount
	resized.emit(new_hp_amount)
	
## Change the maximum value of health and fill the health bar
func resize_and_fill(new_hp_amount: float) -> void:
	resize(new_hp_amount)
	fill()
	
## Change the target health value and the current health value
func set_value(new_value: float) -> void:
	target_value = minf(new_value, max_value)
	value = target_value

func is_hurtable() -> bool:
	return not (invincible or died or (get_parent().has_method("is_hurtable") and not get_parent().is_hurtable()))

func get_last_attacker() -> Node:
	return attacker_body
