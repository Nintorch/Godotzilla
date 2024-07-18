extends "res://Scripts/Objects/Enemies/BaseEnemy.gd"

const ROCKET_LAUNCHER_ROCKET = preload("res://Objects/Levels/Enemies/RocketLauncherRocket.tscn")
const CAPSULE := preload("res://Objects/Levels/Capsule.tscn")
const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var launched := false

func _ready() -> void:
	animation_player.play("idle")

func _process(_delta: float) -> void:
	if position.x < Global.player.position.x + 100:
		launch()
		
func launch() -> void:
	if not launched:
		launched = true
		animation_player.play("launching")
		await animation_player.animation_finished
		# In case if the launcher was destroyed while it was preparing for launch
		if animation_player.current_animation == "dead":
			return
		animation_player.play("launched")
		
		var rocket := ROCKET_LAUNCHER_ROCKET.instantiate()
		rocket.position = position + Vector2(7, -7)
		get_parent().add_child(rocket)
		rocket.attack_component.objects_to_ignore.append(self)

func _on_health_component_dead() -> void:
	$HealthComponent.queue_free()
	launched = true
	start_destroy_sfx()
	
	var explosion := EXPLOSION.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	
	var capsule := CAPSULE.instantiate()
	Global.get_current_scene().call_deferred("add_child", capsule)
	await get_tree().process_frame
	capsule.initialize(global_position, "health")
	
	animation_player.play("dead")
	
