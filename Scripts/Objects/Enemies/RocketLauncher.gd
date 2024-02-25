extends "res://Scripts/Objects/Enemies/BaseEnemy.gd"

const CAPSULE = preload("res://Objects/Capsule.tscn")
const ROCKET_LAUNCHER_ROCKET = preload("res://Objects/Levels/Enemies/RocketLauncherRocket.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var launched := false

func _ready() -> void:
	animation_player.play("idle")

func _process(delta: float) -> void:
	if position.x < Global.player.position.x + 100:
		launch()
		
func launch() -> void:
	if not launched:
		launched = true
		animation_player.play("launching")
		await animation_player.animation_finished
		animation_player.play("launched")
		
		var rocket := ROCKET_LAUNCHER_ROCKET.instantiate()
		rocket.position = position + Vector2(7, -7)
		get_parent().add_child(rocket)
		rocket.attack_component.objects_to_ignore.append(self)

func _on_health_component_dead() -> void:
	destroy_sfx.play()
	
	get_parent().add_child(Explosion.new(global_position))
	
	var capsule := CAPSULE.instantiate()
	Global.get_current_scene().call_deferred("add_child", capsule)
	await get_tree().process_frame
	capsule.initialize(global_position, "health")
	
	animation_player.play("dead")
	
