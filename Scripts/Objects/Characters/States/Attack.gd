extends "res://Scripts/Objects/Characters/States/PlayerState.gd"

var move_state: StateMachineState
var current_attack: AttackDescription
var save_state: PlayerCharacter.State

var attack_component: AttackComponent

#region State methods
func state_init() -> void:
	attack_component = player.attack
	move_state = player.state.states_list[player.move_state]
	
	attack_component.attack_started.connect(attack_before)
	attack_component.attack_finished.connect(attack_after)
	
var save_allow_direction_changing := false
func state_entered() -> void:
	save_allow_direction_changing = player.allow_direction_changing
	player.allow_direction_changing = false
	
func state_exited() -> void:
	player.allow_direction_changing = save_allow_direction_changing
	attack_component.stop_attack()
	
func is_still_attacking() -> bool:
	return player.state.current == PlayerCharacter.State.ATTACK

func _process(delta: float) -> void:
	# Allow the player to move while attacking
	move_state.move(delta)
#endregion

func attack_before(attack: AttackDescription) -> void:
	save_state = player.state.current
	player.state.current = PlayerCharacter.State.ATTACK
	current_attack = attack
	
func attack_after(attack: AttackDescription) -> void:
	player.state.current = save_state
