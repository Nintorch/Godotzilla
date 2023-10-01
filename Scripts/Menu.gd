extends Node2D

@onready var main_menu: Node2D = get_parent()
var options: Array[Control]

func _ready() -> void:
	options = []
	for c in get_children():
		if c.name.begins_with("Opt"):
			options.append(c)

func menu_select(_id: int) -> void:
	pass

func menu_process(_delta: float) -> void:
	pass
