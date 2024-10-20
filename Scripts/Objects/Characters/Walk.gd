extends State

# Move state is used for characters that walk on the ground.
# This state consists of not only walking but also crouching and jumping.
# This state also includes the movement for flying characters.

@onready var player := parent as PlayerCharacter

var walk_frame := 0.0
var walk_frames := 0
var walk_frame_speed := 0

var jumping := false
var jump_speed := -2 * 60

func state_init() -> void:
	
	if not player.is_flying():
		walk_frames = player.body.sprite_frames.get_frame_count("Walk")

	# This
	walk_frame_speed = player.skin.walk_frame_speed
	
	# Instead of this :)
	#match player.character:
		#PlayerCharacter.Type.GODZILLA:
			#walk_frame_speed = 9
			## # You can change the jumping speed for your character like this
			## jump_speed = -1 * 60
		#PlayerCharacter.Type.NOTBARAGON:
			#walk_frame_speed = 6

func _process(delta: float) -> void:
	move(delta)
	player.skin.walk_process()

func move(delta: float) -> void:
	var dirx: float = signf(player.inputs[PlayerCharacter.Inputs.XINPUT])
	if dirx:
		player.velocity.x = player.move_speed * dirx
		
		if player.allow_direction_changing:
			player.direction = int(signf(dirx))
			
		walk_frame = wrapf(
			walk_frame + walk_frame_speed * delta * dirx * player.direction,
			0, walk_frames)
			
		if player.body.animation == "Walk":
			player.body.frame = int(walk_frame)
	else:
		player.velocity.x = 0
		
	var diry: float = player.inputs[PlayerCharacter.Inputs.YINPUT]
	
	# Jump!
	if player.is_on_floor() and diry < -0.4:
		player.velocity.y = jump_speed
		jumping = true
	
	# Variable jump height
	if not player.is_on_floor() and jumping:
		if diry < -0.4 and player.velocity.y < -1.95 * 60:
			player.velocity.y -= 216 * delta
		if player.velocity.y < 0 and diry >= -0.4:
			jumping = false
			player.velocity.y = 0
	
	# Crouch
	if diry > 0.4 and player.body.sprite_frames.has_animation("Crouch"):
		if player.animation_player.current_animation == "Walk"\
			or player.animation_player.current_animation == "":
			player.animation_player.play("Crouch")

	if diry <= 0.4 and player.animation_player.current_animation == "Crouch":
		player.animation_player.play("RESET")

func reset() -> void:
	walk_frame = 0
