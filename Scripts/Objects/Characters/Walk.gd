extends "res://Scripts/Objects/Characters/State.gd"

# Move state is used for characters that walk on the ground.
# This state consists of not only walking but also crouching and jumping.
# This state also includes the movement for flying characters.

var walk_frame = 0.0
var walk_frames = 0
var walk_frame_speed = 0

var jumping = false

const JUMP_SPEED = -2 * 60

func state_init() -> void:
	if not parent.is_flying():
		walk_frames = parent.body.sprite_frames.get_frame_count("Walk")
	
	match parent.character:
		GameCharacter.Type.GODZILLA:
			walk_frame_speed = 9

func _process(delta: float) -> void:
	move(delta)
	
	# Attacks
	match parent.character:
		GameCharacter.Type.GODZILLA:
			common_ground_attacks()
			if parent.animation_player.current_animation == "Crouch" \
				and parent.inputs_pressed[GameCharacter.Inputs.B]:
					parent.use_attack(GameCharacter.Attack.TAIL_WHIP)
			if parent.inputs_pressed[GameCharacter.Inputs.START] \
				and parent.power.value >= 6 * 8:
				parent.use_attack(GameCharacter.Attack.HEAT_BEAM)
	
func common_ground_attacks() -> void:
	if parent.inputs_pressed[GameCharacter.Inputs.A]:
		parent.use_attack(GameCharacter.Attack.PUNCH)
	if parent.animation_player.current_animation != "Crouch" \
		and parent.inputs_pressed[GameCharacter.Inputs.B]:
			parent.use_attack(GameCharacter.Attack.KICK)

func move(delta: float):
	var dirx: float = signf(parent.inputs[GameCharacter.Inputs.XINPUT])
	if dirx:
		parent.velocity.x = parent.move_speed * dirx
		
		if parent.allow_direction_changing:
			parent.direction = signi(dirx)
			
		walk_frame = wrapf(
			walk_frame + walk_frame_speed * delta * dirx * parent.direction,
			0, walk_frames)
			
		if parent.body.animation == "Walk":
			parent.body.frame = int(walk_frame)
	else:
		parent.velocity.x = 0
		
	var diry: float = parent.inputs[GameCharacter.Inputs.YINPUT]
	
	if parent.is_on_floor() and diry < -0.4:
		parent.velocity.y = JUMP_SPEED
		jumping = true
	
	if not parent.is_on_floor() and jumping:
		if diry < -0.4 and parent.velocity.y < -1.95 * 60:
			parent.velocity.y -= 216 * delta
		if parent.velocity.y < 0 and diry >= -0.4:
			jumping = false
			parent.velocity.y = 0
	
	if diry > 0.4:
		if parent.animation_player.current_animation == "Walk"\
			or parent.animation_player.current_animation == "":
			parent.animation_player.play("Crouch")
	
	if diry <= 0.4 and parent.animation_player.current_animation == "Crouch":
		parent.animation_player.play("RESET")

func reset() -> void:
	walk_frame = 0
