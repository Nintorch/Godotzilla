extends "res://Scripts/Levels/Bosses/BaseBoss.gd"
	
enum BossState {
	NONE,
	IDLE,
	MOVING,
}

var state: BossState = BossState.NONE
var time := 40
var attack_time := 0
var simple_attack_time := 0

func boss_ai_start() -> void:
	state = BossState.IDLE
	
func boss_ai_stop() -> void:
	state = BossState.NONE

func boss_ai() -> void:
	if state == BossState.NONE or boss.state.current == boss.State.DEAD:
		return
	
	time -= 1
	
	if boss.position.x < 50:
		boss.position.x = 50
		boss.velocity.x = 0
		state = BossState.IDLE
		
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
		BossState.IDLE:
			boss.inputs[boss.Inputs.XINPUT] = 0
			boss.inputs[boss.Inputs.YINPUT] = 0
			if time <= 0:
				state = BossState.MOVING
				time = 20
				
				boss.inputs[boss.Inputs.XINPUT] = randi_range(-1, 1)
				boss.inputs[boss.Inputs.YINPUT] = randi_range(-1, 1)
		BossState.MOVING:
			if boss.position.y > 160:
				boss.position.y = 160
				boss.velocity.y = 0
			if time <= 0:
				state = BossState.IDLE
				time = randi_range(30, 90)

func spam_bullets() -> void:
	boss.inputs_pressed[boss.Inputs.A] = true
	await get_tree().create_timer(1, false).timeout
	boss.inputs_pressed[boss.Inputs.A] = false
