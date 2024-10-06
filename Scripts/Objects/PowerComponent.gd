class_name PowerComponent
extends Node

@export var value := 10.0
@export var max_value := 10.0
## Power restoration speed (points per second)
@export var restore_speed := 3.0

@onready var old_value := value

signal value_changed(new_value: float)

func _process(delta: float) -> void:
	value = minf(value + restore_speed * delta, max_value)
	if value != old_value:
		old_value = value
		value_changed.emit(value)

func use(amount: float) -> void:
	if value < amount:
		return
	value = maxf(value - amount, 0)

func add(amount: float) -> void:
	value = minf(value + amount, max_value)

func set_empty() -> void:
	value = 0.0
	max_value = 0.0
	restore_speed = 0.0
