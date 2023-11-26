extends TextureRect

func _ready():
	var resolution_x := Global.get_content_size().x
	position.x = (resolution_x - size.x) / 2
