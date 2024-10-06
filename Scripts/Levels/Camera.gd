extends Camera2D

enum CameraMode {
	NORMAL,
	TWO_SIDES,
}

@export var camera_offset_x := 30
@export var target: Node2D
@export var camera_mode := CameraMode.NORMAL

@onready var window_width_half := Global.get_content_size().x / 2

var camera_x_old: float
var camera_current_offset := 0

func _process(_delta: float) -> void:
	camera_x_old = get_screen_center_position().x
	position.y = target.position.y
	match camera_mode:
		# The default camera mode, the one from the original game
		CameraMode.NORMAL:
			if position.x < target.position.x + camera_offset_x \
				and position.x < limit_right - window_width_half:
				position.x = clampf(target.position.x + camera_offset_x,
					window_width_half, limit_right - window_width_half)
				limit_left = max(position.x - window_width_half, 0)
		
		# The camera can move in both sides
		CameraMode.TWO_SIDES:
			var direction: int = target.direction if "direction" in target else 1
			camera_current_offset = roundi(move_toward(
				camera_current_offset,
				camera_offset_x * target.direction,
				2
			))
			position.x = target.position.x + camera_current_offset

func is_camera_moving() -> bool:
	return camera_x_old != get_screen_center_position().x
