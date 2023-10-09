extends Node2D

@onready var main_menu: Node2D = get_parent()
var options: Array[Control]

func _ready() -> void:
	options.assign(get_children().filter(func(c): return c.name.begins_with("Opt")))

func menu_enter() -> void:
	pass

func menu_exit() -> void:
	pass

func menu_select(_id: int) -> void:
	pass

func menu_process(_delta: float) -> void:
	pass
