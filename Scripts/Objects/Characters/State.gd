extends Node

@onready var parent: PlayerCharacter = $"../.."

## The method that is called when the player is ready
func state_init() -> void:
	pass

## The method that is called when the state is enabled
func state_entered() -> void:
	pass

## The method that is called when the state is disabled
func state_exited() -> void:
	pass

func enable() -> void:
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	
func disable() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
