class_name StateMachine
extends Node

@export var initial_state: Node = null
@onready var states_list: Array[State] = []
var current := 0: set = _set_state

func _ready() -> void:
	states_list.assign(get_children().filter(func(c: Node) -> bool: return c is State))
	current = states_list.find(initial_state)

func init() -> void:
	for i in states_list:
		i.state_init()
		if i == states_list[current]:
			i.enable()
			i.state_entered()
		else:
			i.disable()

func _set_state(new_state: int) -> void:
	if current == new_state:
		return
	
	var old_state_node := states_list[current]
	var new_state_node := states_list[new_state]
	
	old_state_node.state_exited()
	old_state_node.disable()
	new_state_node.enable()
	new_state_node.state_entered()
	
	current = new_state
