extends "res://Scripts/Objects/Characters/State.gd"

var move_state: Node
var sfx_step: AudioStreamPlayer
var sfx_roar: AudioStreamPlayer

const CHARACTER_PARAMS = [
	{
		step_sfx_period = 30,
		step_sfx_start = 10,
		target_x = 64,
	},
	{
		step_sfx_period = 15,
		step_sfx_start = 20,
		target_x = 80,
	},
]

var current_params

func state_init() -> void:
	sfx_step = parent.get_sfx("Step")
	sfx_roar = parent.get_sfx("Roar")
	move_state = parent.states_list[parent.move_state]
	current_params = CHARACTER_PARAMS[parent.character]

func _physics_process(delta: float) -> void:
	parent.velocity.x = parent.move_speed
	
	if not parent.is_flying():
		move_state.walk_frame = wrapf(
			move_state.walk_frame + move_state.walk_frame_speed * delta,
			0, move_state.walk_frames)
		parent.body.frame = int(move_state.walk_frame)
		
	if not Global.music.playing:
		if Engine.get_physics_frames() >= current_params.step_sfx_start \
			and Engine.get_physics_frames() % current_params.step_sfx_period == 0:
				sfx_step.play()
			
	if parent.position.x > current_params.target_x:
		parent.state = parent.move_state
		parent.velocity = Vector2(0,0)
		move_state.reset()
		parent.body.frame = 0
		if not Global.music.playing:
			sfx_roar.play()
		parent.intro_ended.emit()
