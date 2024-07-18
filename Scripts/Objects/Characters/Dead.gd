extends "res://Scripts/Objects/Characters/State.gd"

const GAME_OVER_SCENE := preload("res://Scenes/GameOver.tscn")
const EXPLOSION := preload("res://Objects/Levels/Explosion.tscn")

func state_entered() -> void:
	parent.collision_mask = 0
	parent.velocity = Vector2(0, 0.3 * 60)
	parent.animation_player.play("Hurt", -1, 0)
	if parent.is_flying():
		parent.get_node("MothraFloorChecking").collision_mask = 0
	await Global.music.finished
	
	await Global.fade_out(true)
	
	if not is_instance_valid(Global.board):
		Global.change_scene(GAME_OVER_SCENE)
		return
	
	Global.board.selected_piece.remove()
	Global.board.selected_piece = null
		
	if Global.board.get_player_pieces().size() == 0:
		Global.change_scene(GAME_OVER_SCENE)
		return
		
	Global.change_scene_node(Global.board)
	Global.board.returned(not parent.is_player)
	
func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % 5 == 0:
		var explosion := EXPLOSION.instantiate()
		explosion.global_position = parent.global_position
		Global.get_current_scene().add_child(explosion)
