extends StaticBody2D

@export_enum("Top and bottom", "Top only", "Bottom only") var type := 0
@onready var top_part: StaticBody2D = $TopPart
@onready var bottom_part: StaticBody2D = $BottomPart

func _ready() -> void:
	match type:
		1:	bottom_part.queue_free()
		2:	top_part.queue_free()
		
func _process(_delta: float) -> void:
	if not is_instance_valid(top_part) and not is_instance_valid(bottom_part):
		queue_free()

func _on_top_health_damaged(_amount: float, _hurt_time: float) -> void:
	var top_sprite := $TopPart/Sprite
	top_sprite.region_rect.position.x = 439
	top_sprite.region_rect.position.y = 21
	
func _on_bottom_health_damaged(_amount: float, _hurt_time: float) -> void:
	$BottomPart/Sprite.region_rect.position.x = 429

func _on_top_health_dead() -> void:
	top_part.queue_free()
	Global.player.add_xp(10)
	Global.add_score(100)

func _on_bottom_health_dead() -> void:
	bottom_part.queue_free()
	Global.player.add_xp(10)
	Global.add_score(100)
