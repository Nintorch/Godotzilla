extends AnimatedSprite2D

@onready var flash_timer = $FlashTimer
@onready var destroy_timer = $DestroyTimer

var player: GameCharacter
var id := 0

func setup(init_id: int, init_player: GameCharacter):
	frame = init_id
	id = init_id
	visible = false
	player = init_player
	
func start() -> void:
	visible = true
	destroy_timer.start()
	
func _physics_process(_delta):
	position.y = player.save_position[id].y - id - player.position.y
	
func _on_timer_timeout():
	if animation == "default":
		animation = "highlight"
	else:
		animation = "default"
	frame = id

func _on_destroy_timer_timeout():
	queue_free()
