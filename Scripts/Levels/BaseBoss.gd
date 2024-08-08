extends Level

## The amount of XP the player gets when the boss is defeated
@export var xp_amount := 100

@onready var boss: PlayerCharacter = $Boss

func _ready() -> void:
	super._ready()
	player.intro_ended.connect(func(): state = State.IDLE)
	player.health.dead.connect(func(): state = State.NONE)
	boss.health.dead.connect(func():
		get_HUD().boss_timer.stop()
		player.add_xp(xp_amount)
		Global.play_music(preload("res://Audio/Soundtrack/Victory.ogg"))
		player_dead(boss)
		)
		
	if data.boss_piece:
		boss.load_state(data.boss_piece.character_data)
		if Global.board:
			boss.health.dead.connect(func():
				Global.board.selected_piece = data.boss_piece
				)

func _process(delta: float) -> void:
	super._process(delta)

	if player.position.x > boss.position.x - 20:
		player.position.x = boss.position.x - 20
		player.velocity.x = 0
	
	boss_ai()
	
enum State {
	NONE,
	IDLE,
	MOVING,
}

var state: State = State.NONE
var time := 40
var attack_time := 0
var simple_attack_time := 0

func boss_ai() -> void:
	if state == State.NONE or boss.state == boss.State.DEAD:
		return
	
	time -= 1
	
	if boss.position.x < 50:
		boss.position.x = 50
		boss.velocity.x = 0
		state = State.IDLE
		
	if (boss.position.x - player.position.x) < 60:
		attack_time += 1
	elif (boss.position.x - player.position.x) < 100:
		simple_attack_time += 1
		
	if attack_time > 150 and boss.power.value > 3 * 8:
		attack_time = 0
		boss.simulate_input_press(PlayerCharacter.Inputs.START)
		
	if simple_attack_time > 100:
		simple_attack_time = 0
		spam_bullets()
	
	match state:
		State.IDLE:
			boss.inputs[boss.Inputs.XINPUT] = 0
			boss.inputs[boss.Inputs.YINPUT] = 0
			if time <= 0:
				state = State.MOVING
				time = 20
				
				boss.inputs[boss.Inputs.XINPUT] = randi_range(-1, 1)
				boss.inputs[boss.Inputs.YINPUT] = randi_range(-1, 1)
		State.MOVING:
			if boss.position.y > 160:
				boss.position.y = 160
				boss.velocity.y = 0
			if time <= 0:
				state = State.IDLE
				time = randi_range(30, 90)

func spam_bullets() -> void:
	boss.inputs_pressed[boss.Inputs.A] = true
	await get_tree().create_timer(1, false).timeout
	boss.inputs_pressed[boss.Inputs.A] = false


func _on_hud_boss_timer_timeout() -> void:
	boss.save_state(data.boss_piece.character_data)
	
	Global.music_fade_out()
	await Global.fade_out_paused()
	
	Global.change_scene_node(Global.board)
	# true for ignore_boss_moves
	Global.board.returned(true)
