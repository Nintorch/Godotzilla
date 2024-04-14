extends CanvasLayer

@export var player: GameCharacter = null
@export var boss: GameCharacter = null
@export var boss_bar_color: Color
@export var boss_timer_seconds := 60

var vertical_size := 0

signal boss_timer_timeout

func _ready():
	Global.widescreen_changed.connect(adapt_to_content_size)
	adapt_to_content_size()
	
	await Global.get_current_scene().ready
	
	if not is_instance_valid(player):
		printerr("You must provide the player object to the HUD")
		return
		
	setup_character_listener(player, $PlayerCharacter)
	
	# Setup the boss bars if there's a boss in the scene
	if is_instance_valid(boss):
		setup_character_listener(boss, $BossCharacter)
		
		$BgRect.size.y = 72
		vertical_size = 80
		$BossCharacter.visible = true
		var boss_bar: ColorRect = $BossCharacter/BgRect2
		boss_bar.color = boss_bar_color
		boss_bar.size.x = Global.get_content_size().x
		
		var timer_text: Label = $BossCharacter/TimerText
		timer_text.position = $PlayerCharacter/ScoreMeter.position
		timer_text.text = str(boss_timer_seconds)
		
		var timer: Timer = $BossCharacter/Timer
		timer.start()
		timer.timeout.connect(func():
			boss_timer_seconds -= 1
			timer_text.text = str(boss_timer_seconds)
			if boss_timer_seconds <= 0:
				boss_timer_timeout.emit()
				timer.stop()
			)
	else:
		$BgRect.size.y = 48
		vertical_size = 48
		$BossCharacter.visible = false
		
func setup_character_listener(character: GameCharacter, group: Node2D) -> void:
	# Set the character's name in the HUD
	group.get_node("CharacterName").text = character.get_character_name()
	
	var life_bar = group.get_node("Life")
	var power_bar = group.get_node("Power")
	
	# Initial life/power bars and/or level text setup
	
	update_character_level(group, character.level, character.health.max_value / 8)
		
	life_bar.initial_value = character.health.value
	life_bar.target_value = character.health.value
	life_bar.update_style()
	
	# Update the life bar whenever the character's HP changes
	character.health.value_changed.connect(func(new_value: float):
		life_bar.target_value = new_value
		)
	
	# Update the character level (life/power bars and/or level text)
	character.level_amount_changed.connect(
		func(new_value: int, new_bar_count: int):
			update_character_level(group, new_value, new_bar_count)
			)
	
	# Update the power bar
	character.power.value_changed.connect(func(new_value: float):
		power_bar.target_value = new_value
		)
	
func update_character_level(group: Node2D, new_value: int, new_bar_count: int):
	var life_bar = group.get_node("Life")
	var power_bar = group.get_node("Power")
	life_bar.width = new_bar_count
	life_bar.max_value = new_bar_count * 8

	power_bar.width = new_bar_count
	power_bar.max_value = new_bar_count * 8
	
	var level_node = group.get_node_or_null("Level")
	if level_node == null:
		return
		
	var level_str := str(new_value)
	if level_str.length() < 2:
		level_str = "0" + level_str
	level_node.text = "level " + level_str
		
func adapt_to_content_size():
	var width := Global.get_content_size().x
	$BgRect.size.x = width
	$PlayerCharacter/Level.position.x = width - 88
	$PlayerCharacter/LevelBar.position.x = $PlayerCharacter/Level.position.x
	
	var score = $PlayerCharacter/ScoreMeter
	score.position.x = width / 2 - score.size.x / 2 - 8
