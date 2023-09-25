extends "res://Scripts/Objects/Characters/State.gd"

# Walk state is used for characters that walk on the ground.
# This state consists of not only walking but also crouching and jumping.

var walk_frame = 0.0
var walk_frames = 0
var walk_frame_speed = 0

var jumping = false
var jump_speed = -2 * 60

func state_init() -> void:
	walk_frames = char.body.sprite_frames.get_frame_count("Walk")
	walk_frame_speed = 9

func _process(delta: float) -> void:
	walk(delta)
	
	if char.inputs_pressed[GameCharacter.Inputs.A]:
		char.use_attack(GameCharacter.Attack.PUNCH)
	if char.animation_player.current_animation != "Crouch" \
		and char.inputs_pressed[GameCharacter.Inputs.B]:
			char.use_attack(GameCharacter.Attack.KICK)
	
func walk(delta: float):
	var direction = char.inputs[GameCharacter.Inputs.XINPUT]
	if direction:
		char.velocity.x = char.move_speed * direction
		walk_frame = wrapf(
			walk_frame + walk_frame_speed * delta * direction,
			0, walk_frames)
		if char.body.animation == "Walk":
			char.body.frame = int(walk_frame)
	else:
		char.velocity.x = 0
		
	var up_down = char.inputs[GameCharacter.Inputs.YINPUT]
	
	if char.is_on_floor() and up_down < 0:
		char.velocity.y = jump_speed
		jumping = true
	
	if not char.is_on_floor() and jumping:
		if up_down < 0 and char.velocity.y < -1.95 * 60:
			char.velocity.y -= 216 * delta
		if char.velocity.y < 0 and up_down >= 0:
			jumping = false
			char.velocity.y = 0
					
	if char.is_on_floor():
		if up_down > 0:
			if char.animation_player.current_animation == "Walk"\
				or char.animation_player.current_animation == "":
				char.animation_player.play("Crouch")
		
		if up_down <= 0 and char.animation_player.current_animation == "Crouch":
			char.animation_player.play("RESET")
			walk_frame = 0
