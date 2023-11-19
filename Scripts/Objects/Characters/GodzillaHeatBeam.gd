extends AnimatedSprite2D

@onready var flash_timer = $FlashTimer
@onready var destroy_timer = $DestroyTimer

var player: GameCharacter
var id := 0

func setup(id: int):
	frame = id
	self.id = id
	visible = false
	
func start() -> void:
	visible = true
	destroy_timer.start()
	
func _physics_process(delta):
	global_position.y = player.save_position[60 - 1 - id].y
	
func _on_timer_timeout():
	if animation == "default":
		animation = "highlight"
	else:
		animation = "default"
	frame = id

func _on_destroy_timer_timeout():
	queue_free()
