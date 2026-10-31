extends Enemy

const ROCKET_LAUNCHER_ROCKET = preload("uid://kd587533e5l4")

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
		add_sibling(rocket)
		rocket.attack_component.objects_to_ignore.append(self)

func _on_health_component_dead() -> void:
	$HealthComponent.queue_free()
	$AttackComponent.queue_free()
	launched = true

	Global.create_explosion(global_position)
	
	await get_tree().process_frame
	Global.create_capsule(global_position, Global.Capsule.TYPE_HEALTH)
	
	animation_player.play("dead")
	
