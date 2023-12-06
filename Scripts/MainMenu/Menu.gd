extends Node2D

@onready var main_menu: Node2D = get_parent()
var options: Array[Control]

func _ready() -> void:
	options.assign(get_children().filter(func(c: Node) -> bool:
		return c.is_in_group("option")))

func menu_enter() -> void:
	pass

func menu_exit() -> void:
	pass

func menu_select(_id: int) -> void:
	pass
