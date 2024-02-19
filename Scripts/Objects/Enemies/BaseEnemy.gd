extends StaticBody2D

func _on_health_component_damaged(_amount: float, _hurt_time: float) -> void:
	print("Oh no, I was damaged!!11 Nooo1oo!O")

func _on_health_component_dead() -> void:
	print("I'm dead :((((")
	queue_free()
