extends "res://Scripts/Objects/Characters/States/PlayerState.gd"

var move_state: Node

func state_init() -> void:
	move_state = player.state.states_list[player.move_state]

func _physics_process(delta: float) -> void:
	player.velocity.x = player.move_speed
	
	if not player.is_flying():
		var walk_state := move_state as PlayerStateWalk
		walk_state.walk_frame = wrapf(
			walk_state.walk_frame + walk_state.parameters.walking_walk_animation_speed * delta,
			0, walk_state.walk_frames)
		player.body.frame = int(walk_state.walk_frame)
		
	if not Global.music.playing:
		if Engine.get_physics_frames() >= player.skin.intro_step_sfx_start \
		and Engine.get_physics_frames() % player.skin.intro_step_sfx_period \
		== player.skin.intro_step_sfx_offset:
			player.play_sfx("Step")
			
	if player.position.x > player.skin.intro_target_x:
		player.state.current = player.move_state
		player.velocity = Vector2(0,0)
		move_state.reset()
		player.body.frame = 0
		if not Global.music.playing:
			player.play_sfx("Roar")
		player.intro_ended.emit()
