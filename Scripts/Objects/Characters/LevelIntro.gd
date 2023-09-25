extends "res://Scripts/Objects/Characters/State.gd"

@onready var walk_state = $"../Walk"
var sfx_step: AudioStreamPlayer
var sfx_roar: AudioStreamPlayer
var timer = -0.05 # a small offset for step sounds

func _ready() -> void:
	sfx_step = parent.get_sfx("Step")
	sfx_roar = parent.get_sfx("Roar")

func _process(delta: float) -> void:
	parent.velocity.x = parent.move_speed
	
	if parent.character != GameCharacter.Type.MOTHRA:
		walk_state.walk_frame = wrapf(
			walk_state.walk_frame + walk_state.walk_frame_speed * delta,
			0, walk_state.walk_frames)
		parent.body.frame = int(walk_state.walk_frame)
		
		if not Global.music.playing:
			timer += delta
			const step_delay = 0.5
			if timer > step_delay:
				timer -= step_delay
				sfx_step.play()
			
	if parent.position.x > 64:
		parent.set_state(GameCharacter.State.WALK)
		walk_state.walk_frame = 0
		parent.body.frame = 0
		if not Global.music.playing:
			sfx_roar.play()
		Global.level.intro_ended()
