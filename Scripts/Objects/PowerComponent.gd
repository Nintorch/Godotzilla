extends Node

@export var value := 10.0
@export var max_value := 10.0
## Power restoration speed (points per second)
@export var restore_speed := 3.0

func _process(delta: float) -> void:
	value = minf(value + restore_speed * delta, max_value)

func use(amount: float) -> bool:
	if value < amount:
		return false
	value = maxf(value - amount, 0)
	return true
