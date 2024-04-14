extends AnimatedSprite2D

@onready var flash_timer = $FlashTimer
@onready var destroy_timer = $DestroyTimer
@onready var attack: Node2D = $AttackComponent

var player: GameCharacter
var id := 0

func setup(init_id: int, init_player: GameCharacter):
	frame = init_id
	id = init_id
	visible = false
	player = init_player
	
func _ready() -> void:
	attack.objects_to_ignore.append(player)
	attack.set_collision(Vector2(8, 4 * (id+1)), Vector2(0, 2 * (id+1) - 48/2 + 1))
	
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
