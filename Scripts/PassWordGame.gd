extends Node2D

const LEFT_POS := Vector2i(3, 3)
const RIGHT_POS := Vector2i(5, 3)
const END_POS := Vector2i(8, 3)

@onready var input_letters: Label = $PasswordInput/InputLetters
@onready var input_selector: Sprite2D = $PasswordInput/Selector
@onready var password_node: Label = $PasswordBox/Password
@onready var password_selector: Sprite2D = $PasswordBox/Selector

@onready var pwe_node: Label = $PassWordError
@onready var pwe_timer: Timer = $PWETimer

var input_selector_position := Vector2i(0, 0)
# Password selector position
var selector_position := 0
var ignore_input := false

# Letters count per line in input box
var letters_count_line := 0
var special_buttons: Array[Control] = []

var alphabet: PackedStringArray
var password: PackedStringArray = []

# Dictionary of all passwords
# Passwords should be lowercase and stripped from spaces on the right
var passwords := {
	"test": pw_test,
}

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	prepare()
	update_password_text()
	
	Global.play_music(preload("res://Audio/Soundtrack/PassWordGame.ogg"))
	Global.fade_in()
	
func _process(delta: float) -> void:
	if not ignore_input:
		input_selector_process()
		
		if Input.is_action_just_pressed("A"):
			match input_selector_position:
				LEFT_POS:
					move_password_selector(-1)
				RIGHT_POS:
					move_password_selector(1)
				END_POS:
					var current_password := get_password_text()
					if current_password == "":
						leave()
						return
					elif current_password in passwords:
						passwords[current_password].call()
					# Unknown password - pass word error
					else:
						ignore_input = true
						pwe_timer.start()
						
						for i in 5:
							pwe_node.visible = true
							await pwe_timer.timeout
							pwe_node.visible = false
							await pwe_timer.timeout
							
						pwe_timer.stop()
						ignore_input = false
					
				# A letter was selected
				_:
					var letter: String = \
						alphabet[input_selector_position.y][input_selector_position.x]
					password[selector_position] = letter
					update_password_text()
					move_password_selector(1)

func prepare() -> void:
	if not input_letters.text.ends_with(' '):
		input_letters.text += ' '
	
	alphabet = input_letters.text.split('\n')
	letters_count_line = alphabet[0].length()
	
	var result_string := ""
	
	for i in alphabet.size():
		var line = alphabet[i].split()
		if line.size() >= letters_count_line / 2:
			line[letters_count_line / 2 - 1] += ' '
		result_string += " ".join(line) + '\n'
		
	input_letters.text = result_string
	
	special_buttons.assign(get_tree().get_nodes_in_group("special"))
	password.resize(40)
	
func leave() -> void:
	get_tree().paused = true
	
	Global.music_fade_out()
	Global.fade_out()
	await Global.fade_end
	
	get_tree().paused = false
	await get_tree().create_timer(0.5).timeout
	
	Global.change_scene(preload("res://Scenes/MainMenu.tscn"))

func input_selector_process() -> void:
	const LEFT_REMAPS := {
		Vector2i(0,3): END_POS,
		RIGHT_POS: LEFT_POS,
		END_POS: RIGHT_POS,
	}
	const RIGHT_REMAPS := {
		LEFT_POS: RIGHT_POS,
		RIGHT_POS: END_POS,
		END_POS: Vector2i(0,3),
	}
	
	var move := Vector2i()
	if Input.is_action_just_pressed("Left"):
		move.x -= 1
	if Input.is_action_just_pressed("Right"):
		move.x += 1
	if Input.is_action_just_pressed("Up"):
		move.y -= 1
	if Input.is_action_just_pressed("Down"):
		move.y += 1
	
	if move != Vector2i.ZERO:
		if move.x < 0 and input_selector_position in LEFT_REMAPS:
			input_selector_position = Vector2i(LEFT_REMAPS[input_selector_position])
		elif move.x > 0 and input_selector_position in RIGHT_REMAPS:
			input_selector_position = Vector2i(RIGHT_REMAPS[input_selector_position])
		else:
			input_selector_position += move
			input_selector_position.x = \
				wrapi(input_selector_position.x, 0, letters_count_line)
			input_selector_position.y = \
				wrapi(input_selector_position.y, 0, 4)
				
			# If moved vertically and ended up on last line
			if input_selector_position.y == 3 and move.y != 0:
				var special_positions = [
					[LEFT_POS.x, RIGHT_POS.x],
					[RIGHT_POS.x, END_POS.x],
					[END_POS.x, letters_count_line]
				]
				
				for pos in special_positions:
					if input_selector_position.x in range(pos[0], pos[1]):
						input_selector_position.x = pos[0]
		move_input_selector()
	
func move_input_selector() -> void:
	input_selector.position.x = input_selector_position.x * 16 + \
		(8 if input_selector_position.x >= letters_count_line / 2 else 0)
	input_selector.position.y = input_selector_position.y * 24
	
func move_to_button(button: Control) -> void:
	input_selector.position = button.position

func get_box(button: Control) -> Rect2:
	return Rect2(button.position, button.size)
	
func update_password_text() -> void:
	var string := "".join(password)
	var result := ""
	for i in range(0, 40, 10):
		result += string.substr(i, 10) + \
			("  " if i % 20 == 0 else '\n')
	password_node.text = result
	
func move_password_selector(pos: int) -> void:
	selector_position += pos
	if selector_position < 0:
		selector_position = 0
	elif selector_position > 40-1:
		selector_position = 40-1
		
	var posx := selector_position % 20
	var posy := selector_position / 20
	password_selector.position.x = posx * 8 + (16 if posx >= 10 else 0)
	password_selector.position.y = posy * 24

func get_password_text() -> String:
	return "".join(password).rstrip(' ')
	
# Password actions below

# Just a test password
func pw_test() -> void:
	ignore_input = true
	
	Global.music_fade_out()
	Global.fade_out(Global.FADE_WHITE)
	await Global.fade_end
	
	await get_tree().create_timer(1).timeout
	
	Global.play_music(preload("res://Audio/Soundtrack/PassWordGame.ogg"))
	Global.fade_in(Global.FADE_WHITE)
	await Global.fade_end
	
	ignore_input = false
