extends "res://Scripts/Objects/Characters/State.gd"

@onready var move_state = $"../Move"
var sfx_step: AudioStreamPlayer
var sfx_roar: AudioStreamPlayer
var timer = -0.05 # a small offset for step sounds

func _ready() -> void:
	sfx_step = parent.get_sfx("Step")
	sfx_roar = parent.get_sfx("Roar")

func _process(delta: float) -> void:
	parent.velocity.x = parent.move_speed
	
	if parent.character != GameCharacter.Type.MOTHRA:
		move_state.walk_frame = wrapf(
			move_state.walk_frame + move_state.walk_frame_speed * delta,
			0, move_state.walk_frames)
		parent.body.frame = int(move_state.walk_frame)
		
		if not Global.music.playing:
			if Engine.get_physics_frames() % 30 == 0:
				sfx_step.play()
			
	if parent.position.x > 64:
		parent.set_state(GameCharacter.State.MOVE)
		move_state.walk_frame = 0
		parent.body.frame = 0
		if not Global.music.playing:
			sfx_roar.play()
		Global.level.intro_ended()
