extends "res://Scripts/Objects/Characters/PlayerState.gd"

var move_state: Node

const CHARACTER_PARAMS := [
	{
		step_sfx_period = 30,
		step_sfx_start = 15,
		step_sfx_offset = 10,
		target_x = 64,
	},
	{
		step_sfx_period = 15,
		step_sfx_start = 20,
		step_sfx_offset = 0,
		target_x = 80,
	},
]

var current_params: Dictionary

func state_init() -> void:
	move_state = player.state.states_list[player.move_state]
	current_params = CHARACTER_PARAMS[player.character]

func _physics_process(delta: float) -> void:
	player.velocity.x = player.move_speed
	
	if not player.is_flying():
		move_state.walk_frame = wrapf(
			move_state.walk_frame + move_state.walk_frame_speed * delta,
			0, move_state.walk_frames)
		player.body.frame = int(move_state.walk_frame)
		
	if not Global.music.playing:
		if Engine.get_physics_frames() >= current_params.step_sfx_start \
		and Engine.get_physics_frames() % current_params.step_sfx_period \
		== current_params.step_sfx_offset:
			player.play_sfx("Step")
			
	if player.position.x > current_params.target_x:
		player.state.current = player.move_state
		player.velocity = Vector2(0,0)
		move_state.reset()
		player.body.frame = 0
		if not Global.music.playing:
			player.play_sfx("Roar")
		player.intro_ended.emit()
