extends "res://Scripts/Objects/Characters/State.gd"

# Walk state is used for characters that walk on the ground.
# This state consists of not only walking but also crouching and jumping.

var walk_frame = 0.0
var walk_frames = 0
var walk_frame_speed = 0

var jumping = false
var jump_speed = -2 * 60

func state_init() -> void:
	walk_frames = parent.body.sprite_frames.get_frame_count("Walk")
	walk_frame_speed = 9

func _process(delta: float) -> void:
	walk(delta)
	
	if parent.inputs_pressed[GameCharacter.Inputs.A]:
		parent.use_attack(GameCharacter.Attack.PUNCH)
	if parent.animation_player.current_animation != "Crouch" \
		and parent.inputs_pressed[GameCharacter.Inputs.B]:
			parent.use_attack(GameCharacter.Attack.KICK)
	
func walk(delta: float):
	var direction = parent.inputs[GameCharacter.Inputs.XINPUT]
	if direction:
		parent.velocity.x = parent.move_speed * direction
		walk_frame = wrapf(
			walk_frame + walk_frame_speed * delta * direction,
			0, walk_frames)
		if parent.body.animation == "Walk":
			parent.body.frame = int(walk_frame)
	else:
		parent.velocity.x = 0
		
	var up_down = parent.inputs[GameCharacter.Inputs.YINPUT]
	
	if parent.is_on_floor() and up_down < 0:
		parent.velocity.y = jump_speed
		jumping = true
	
	if not parent.is_on_floor() and jumping:
		if up_down < 0 and parent.velocity.y < -1.95 * 60:
			parent.velocity.y -= 216 * delta
		if parent.velocity.y < 0 and up_down >= 0:
			jumping = false
			parent.velocity.y = 0
					
	if parent.is_on_floor():
		if up_down > 0:
			if parent.animation_player.current_animation == "Walk"\
				or parent.animation_player.current_animation == "":
				parent.animation_player.play("Crouch")
		
		if up_down <= 0 and parent.animation_player.current_animation == "Crouch":
			parent.animation_player.play("RESET")
			walk_frame = 0