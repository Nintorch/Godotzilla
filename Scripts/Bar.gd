@tool
extends Control

enum Style {
	STYLE1,
	STYLE2,
}

## Style 1 is the style for player's power and life bars.
@export var style = Style.STYLE1
## Bar count for style 1, maximum value for style 2
@export var width = 1
## -1 for full
@export var initial_value = -1

@export var color1 = Color(1, 1, 1)
@export var color2 = Color(0.71, 0.19, 0.125)

var value: float = 0
var target_value: float = 0
const speed = 1 * 60
var max_value: float = 0

func _ready() -> void:
	update_style()

func _process(delta: float) -> void:
	if target_value > max_value or value > max_value:
		target_value = max_value
		value = max_value

	if int(value) != target_value:
		value = move_toward(value, target_value, speed * delta)
		match style:
			Style.STYLE1:
				$Style1/RedBar.size.x = int(value)
			Style.STYLE2:
				$Style2/BarColor.size.x = (value / max_value) * $Style2/BarBG.size.x

func update_style() -> void:
	match style:
		Style.STYLE1:
			$Style1/BarsOutline.size.x = width * 8 + 1
			$Style1/BarsOutline.self_modulate = color1
			$Style1/RedBar.color = color2
			max_value = width * 8
			
			if initial_value < 0:
				value = max_value
			else:
				value = initial_value
				
			$Style1/RedBar.size.x = value
			
		Style.STYLE2:
			$Style1.visible = false
			$Style2.visible = true
			$Style2/BarBG.color = color1
			$Style2/BarBG.size.x = size.x
			$Style2/BarColor.color = color2
			max_value = width
			
			if initial_value < 0:
				value = max_value
			else:
				value = initial_value
				
			$Style2/BarColor.size.x = (value / max_value) * $Style2/BarBG.size.x

	target_value = value
