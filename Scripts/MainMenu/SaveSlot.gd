extends Control

@onready var save_exists: Node2D = $SaveExists
@onready var doesnt_exist: Node2D = $DoesntExist
@onready var border: NinePatchRect = $Border

var save_id := 0
var planet: BoardDescription = null

func _ready() -> void:
	save_exists.visible = false
	doesnt_exist.visible = false

func set_data(psave_id: int, pplanet: BoardDescription) -> void:
	save_exists.visible = true
	
	self.save_id = psave_id
	$SaveExists/SaveID.text = "save " + str(psave_id + 1)
	
	self.planet = pplanet
	$SaveExists/PlanetName.text = pplanet.name.to_lower()
	
	if planet.icon != null:
		$SaveExists/PlanetIcon.texture = pplanet.icon
	
func set_data_empty(psave_id: int) -> void:
	doesnt_exist.visible = true
	$DoesntExist/SaveID.text = "save " + str(psave_id + 1)

func select() -> void:
	border.self_modulate = Color("b53120")
	
func deselect() -> void:
	border.self_modulate = Color.WHITE
