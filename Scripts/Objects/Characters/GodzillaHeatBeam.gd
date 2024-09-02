extends AnimatedSprite2D

@onready var flash_timer := $FlashTimer
@onready var destroy_timer := $DestroyTimer
@onready var attack: Node2D = $AttackComponent

var player: PlayerCharacter
var id := 0
var particle_array: Array[AnimatedSprite2D]

func setup(init_id: int, init_player: PlayerCharacter) -> void:
	frame = init_id
	id = init_id
	visible = false
	player = init_player
	
func _ready() -> void:
	attack.objects_to_ignore.append(player)
	attack.set_collision(Vector2(8, 4 * (id+1)), Vector2(0, 2 * (id+1) - 48/2 + 1))
	attack.enemy = player.attack.enemy
	
func start() -> void:
	visible = true
	destroy_timer.start()
	
func _physics_process(_delta: float) -> void:
	position.y = player.save_position[id].y - id - player.position.y
	
func _on_timer_timeout() -> void:
	if animation == "default":
		animation = "highlight"
	else:
		animation = "default"
	frame = id

func _on_destroy_timer_timeout() -> void:
	queue_free()

func _on_attack_component_attacked(body: Node2D, _amount: float) -> void:
	for particle in particle_array:
		if is_instance_valid(particle):
			particle.attack.objects_to_ignore.append(body)
