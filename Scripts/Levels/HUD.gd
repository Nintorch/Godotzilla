extends CanvasLayer

@export var player: GameCharacter = null
@export var boss: GameCharacter = null
@export var boss_bar_color: Color

signal hud_update

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.widescreen_changed.connect(adapt_to_content_size)
	adapt_to_content_size()
	
	if is_instance_valid(boss):
		$BgRect.size.y = 72
		$BossCharacter.visible = true
		$BossCharacter/BgRect2.color = boss_bar_color
	else:
		$BgRect.size.y = 48
		$BossCharacter.visible = false
		
	await Global.get_current_scene().ready
	if not is_instance_valid(player):
		printerr("You must provide the player object to the HUD")
		return
		
	setup_character_listener(player, $PlayerCharacter)
	if is_instance_valid(boss):
		setup_character_listener(boss, $BossCharacter)
		
func setup_character_listener(character: GameCharacter, group: Node2D) -> void:
	group.get_node("CharacterName").text = character.get_character_name()
	
	var life_bar = group.get_node("Life")
	var power_bar = group.get_node("Power")
	
	update_character_level(character, group,
		character.level, character.health.max_value / 8)
		
	life_bar.initial_value = character.health.value
	life_bar.target_value = character.health.value
	life_bar.update_style()
	
	character.life_amount_changed.connect(func(new_value: float):
		life_bar.target_value = new_value
		)
		
	character.level_amount_changed.connect(
		func(new_value: int, new_bar_count: int):
			update_character_level(character, group, new_value, new_bar_count)
			)
	
	hud_update.connect(func():
		power_bar.target_value = character.power.value
		)
		
func update_character_level(character: GameCharacter, group: Node2D,
	new_value: int, new_bar_count: int):
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
	
func _process(delta: float) -> void:
	hud_update.emit()
		
func adapt_to_content_size():
	var width := Global.get_content_size().x
	$BgRect.size.x = width
	$PlayerCharacter/Level.position.x = width - 88
	$PlayerCharacter/LevelBar.position.x = $PlayerCharacter/Level.position.x
	
	var score = $PlayerCharacter/ScoreMeter
	score.position.x = width / 2 - score.size.x / 2 - 8
