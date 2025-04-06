class_name StateMachine extends Node

@export var initial_state: Node = null
@onready var states_list: Array[StateMachineState] = []
var current := 0: set = _set_state

func _ready() -> void:
	states_list.assign(get_children().filter(func(c: Node) -> bool: return c is StateMachineState))
	current = states_list.find(initial_state)

func init() -> void:
	for i in states_list:
		i.state_init()

## Don't call this method directly, use "current = your_value_here".
## Why? For consistency and for looks :D 
func _set_state(new_state: int) -> void:
	if current == new_state:
		return
	
	states_list[current].state_exited()
	for state in states_list:
		state.disable()
	states_list[new_state].enable()
	states_list[new_state].state_entered()
	
	current = new_state
