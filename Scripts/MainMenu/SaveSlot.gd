extends Control

const BOARD_PIECE := preload("res://Objects/Boards/Piece.tscn")

@onready var save_exists: Node2D = $SaveExists
@onready var doesnt_exist: Node2D = $DoesntExist
@onready var border: NinePatchRect = $Border

var save_id := 0
var planet: BoardDescription = null

var pieces: Array[BoardPiece] = []

func _ready() -> void:
	save_exists.visible = false
	doesnt_exist.visible = false

func set_data(psave_id: int, pplanet: BoardDescription, save_data: Dictionary) -> void:
	save_exists.visible = true
	doesnt_exist.visible = false
	
	var group := $SaveExists
	
	self.save_id = psave_id
	$SaveExists/SaveID.text = "save " + str(psave_id + 1)
	
	self.planet = pplanet
	$SaveExists/PlanetName.text = pplanet.name.to_lower()
	
	if planet.icon != null:
		$SaveExists/PlanetIcon.texture = pplanet.icon
	
	# Load characters from the save
	var characters: Array[PlayerCharacter.Type] = save_data["board_data"]["player_characters"]
	characters.reverse()
	var position_x := 24.0
	for character: PlayerCharacter.Type in characters:
		var piece := BOARD_PIECE.instantiate()
		piece.piece_character = character
		group.add_child(piece)
		piece.position = Vector2(position_x, 24.0)
		pieces.append(piece)
		position_x += 8
	
func set_data_empty(psave_id: int) -> void:
	save_exists.visible = false
	doesnt_exist.visible = true
	pieces = []
	$DoesntExist/SaveID.text = "save " + str(psave_id + 1)

func select() -> void:
	border.self_modulate = Color("b53120")
	for piece in pieces:
		piece.select()
	
func deselect() -> void:
	border.self_modulate = Color.WHITE
	for piece in pieces:
		piece.deselect()
