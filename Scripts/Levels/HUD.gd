extends CanvasLayer

@export var boss = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.widescreen_changed.connect(adapt_to_content_size)
	
	adapt_to_content_size()
	$PlayerCharacter/CharacterName.text = Global.player.get_character_name()
	if boss:
		$BgRect.size.y = 72
		$BossCharacter.visible = true
	else:
		$BgRect.size.y = 48
		$BossCharacter.visible = false
		
func adapt_to_content_size():
	$BgRect.size.x = Global.get_content_size().x
	$PlayerCharacter/Level.position.x = Global.get_content_size().x - 88
	$PlayerCharacter/LevelBar.position.x = $PlayerCharacter/Level.position.x
