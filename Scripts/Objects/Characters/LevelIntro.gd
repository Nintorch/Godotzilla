extends "res://Scripts/Objects/Characters/State.gd"

var move_state: Node
var sfx_step: AudioStreamPlayer
var sfx_roar: AudioStreamPlayer
var timer = -0.05 # a small offset for step sounds
var target_x := 64

func state_init() -> void:
	sfx_step = parent.get_sfx("Step")
	sfx_roar = parent.get_sfx("Roar")
	move_state = parent.states_list[parent.move_state]
		
	if parent.character == GameCharacter.Type.MOTHRA:
		target_x = 80

func _physics_process(delta: float) -> void:
	parent.velocity.x = parent.move_speed
	
	if not parent.is_flying():
		move_state.walk_frame = wrapf(
			move_state.walk_frame + move_state.walk_frame_speed * delta,
			0, move_state.walk_frames)
		parent.body.frame = int(move_state.walk_frame)
		
		if not Global.music.playing:
			if Engine.get_physics_frames() % 30 == 0:
				sfx_step.play()
			
	if parent.position.x > target_x:
		parent.set_state(parent.move_state)
		parent.velocity = Vector2(0,0)
		move_state.reset()
		parent.body.frame = 0
		if not Global.music.playing:
			sfx_roar.play()
		Global.get_current_scene().intro_ended()
