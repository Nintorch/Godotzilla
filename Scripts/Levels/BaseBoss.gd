extends Level

@onready var boss: GameCharacter = $Boss

func _ready() -> void:
	super._ready()
	player.intro_ended.connect(func(): state = State.IDLE)

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
		boss.inputs_pressed[boss.Inputs.START] = true
		await get_tree().process_frame
		boss.inputs_pressed[boss.Inputs.START] = false
		
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
