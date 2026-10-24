@abstract class_name GameCharacter extends CharacterBody2D

const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

@onready var health: HealthComponent = $HealthComponent
@onready var power: PowerComponent = $PowerComponent

var _death_animation := false

func _physics_process(delta: float) -> void:
	if _death_animation:
		velocity = Vector2(0, 0.3 * 60)
		if Engine.get_physics_frames() % 5 == 0:
			var explosion := EXPLOSION.instantiate()
			explosion.global_position = global_position
			add_sibling(explosion)
			Global.play_global_sfx("Explosion")

func start_death_animation() -> void:
	_death_animation = true
	collision_layer = 0
	collision_mask = 0
	
@abstract func get_character_name() -> String
@abstract func is_hurtable() -> bool

func should_replay_after_death() -> bool:
	return false

## Load the character data from a board piece
func load_state(data: BoardPiece.CharacterData = null) -> void:
	if data == null:
		return
		
	var bar_value := data.bars * 8
	health.resize(bar_value)
	health.set_value(data.hp)
	power.max_value = bar_value
	power.value = bar_value

## Save the character data into a board piece
func save_state(data: BoardPiece.CharacterData = null) -> void:
	if data == null:
		return
	data.hp = health.value
	data.bars = int(power.max_value / 8)
