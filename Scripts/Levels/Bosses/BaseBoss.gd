extends Level

## The amount of XP the player gets when the boss is defeated
@export var xp_amount := 100
## The amount of score the player gets when the boss is defeated
@export var score_amount := 110000

@onready var boss: PlayerCharacter = $Boss

func _ready() -> void:
	super._ready()
	player.intro_ended.connect(boss_ai_start)
	player.health.dead.connect(boss_ai_stop)
	
	boss.health.damaged.connect(func(amount: float, _hurt_time: float) -> void:
		Global.add_score(20 * int(amount))
		)
	boss.health.dead.connect(func() -> void:
		$HUD.boss_timer_second.stop()
		player.add_xp(xp_amount)
		Global.play_music(preload("res://Audio/Soundtrack/Victory.ogg"))
		save_player_state()
		player_dead(boss, data.boss_piece)
		Global.add_score(score_amount, 10000)
		)
		
	if data.boss_piece:
		boss.load_state(data.boss_piece.character_data)

func _process(delta: float) -> void:
	super._process(delta)

	if player.position.x > boss.position.x - 20:
		player.position.x = boss.position.x - 20
		player.velocity.x = 0
		
	if boss.position.x > camera.limit_right - 10:
		boss.position.x = camera.limit_right - 10
		boss.velocity.x = 0.0
	
	boss_ai()
	
func _on_hud_boss_timer_timeout() -> void:
	boss.save_state(data.boss_piece.character_data)
	
	Global.music_fade_out()
	await Global.fade_out_paused()
	
	Global.change_scene_node(Global.board)
	# true for ignore_boss_moves
	Global.board.returned(true)
	
func boss_ai_start() -> void:
	pass

func boss_ai() -> void:
	printerr("This boss AI has not been coded in or incorrectly overriden")

func boss_ai_stop() -> void:
	pass
