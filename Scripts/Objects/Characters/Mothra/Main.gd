extends PlayerSkin

func _init() -> void:
	character_name = "Mothra"
	bar_count = 8
	
func _ready() -> void:
	player.get_sfx("Step").stream = load("res://Audio/SFX/MothraStep.wav")
	player.get_sfx("Roar").stream = load("res://Audio/SFX/MothraRoar.wav")
	player.move_state = PlayerCharacter.State.FLY
	player.position.y -= 40
	player.move_speed = 2 * 60
	
	if player.is_player and player.enable_intro:
		player.position.x = -37
