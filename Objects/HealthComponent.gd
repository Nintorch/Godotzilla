extends Node

## Health points
@export var hp := 10.0
@export var hp_max := 10.0

var died := false

signal damaged(amount: float, hurt_time: float)
signal healed(amount: float)
signal dead

# TODO: invincibility time

# Returns true if the object died (hp reached 0)
func damage(amount: float, hurt_time: float = -1) -> bool:
	if amount <= 0:
		return false
	elif died:
		return true
		
	hp = maxf(hp - amount, 0)
	if hp > 0:
		damaged.emit(amount, hurt_time)
		return true
	else:
		died = true
		dead.emit()
		return false
		
func heal(amount: float) -> void:
	if amount <= 0 or hp >= hp_max or died:
		return
		
	if hp + amount <= hp_max:
		hp += amount
		healed.emit(amount)
	else:
		var old_hp = hp
		hp = hp_max
		healed.emit(hp_max - old_hp)
