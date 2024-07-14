extends Node

## Health points
@export var value := 10.0
@export var max_value := 10.0
@export var enemy := false
@export var invincibility_time_seconds := 0.0 # in seconds

var died := false
var invincible := false

signal value_changed(new_value: float)
signal damaged(amount: float, hurt_time: float)
signal dead
signal healed(amount: float)

# Returns true if the object died (value reached 0)
func damage(amount: float, hurt_time: float = -1) -> bool:
	if amount <= 0 \
		or (get_parent().has_method("is_hurtable")
		and not get_parent().is_hurtable()) \
		or invincible:
		return false
	elif died:
		return true
		
	value = maxf(value - amount, 0)
	value_changed.emit(value)
	if value > 0:
		damaged.emit(amount, hurt_time)
		if invincibility_time_seconds > 0.0:
			invincible = true
			get_tree().create_timer(invincibility_time_seconds, false).timeout.connect(func():
				invincible = false
				)
		return true
	else:
		died = true
		dead.emit()
		return false
		
func heal(amount: float) -> void:
	if amount <= 0 or value >= max_value or died:
		return
		
	if value + amount <= max_value:
		value += amount
		healed.emit(amount)
	else:
		var old_value = value
		value = max_value
		healed.emit(max_value - old_value)
