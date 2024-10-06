extends Node2D

@export var music: AudioStream
@onready var text_node: RichTextLabel = $CenterContainer/TextNode
@onready var licensing: Label = $Licensing
var current_text := 0
var texts: Array[String]

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	$CenterContainer.size = Vector2(Global.get_default_resolution())
	
	texts.assign(Array(FileAccess.open("res://Other/Credits.txt", FileAccess.READ) \
		.get_as_text().split("==")).map(func(i: String) -> String: return i.strip_edges()))
		
	licensing.hide()
	licensing.position.y = Global.get_content_size().y
	
	Global.play_music(music)
	display_text()
	Global.fade_in()
	
func _process(delta: float) -> void:
	if not Global.is_fading():
		if Global.any_action_button_pressed():
			next_text()
		elif Input.is_action_just_pressed("Exit"):
			exit()
		
		if licensing.visible:
			var diry := signf(Input.get_axis("Up", "Down"))
			var speed := 1 if is_zero_approx(diry) else	6 if diry > 0.4 else 0
			licensing.position.y -= speed * 60 * delta

func display_text() -> void:
	if current_text == texts.size():
		text_node.text = ""
		await get_tree().create_timer(0.1).timeout
		prepare_licensing_text()
		return
	var text := "[center]%s[/center]" % texts[current_text]
	text_node.text = text
	
func prepare_licensing_text() -> void:
	var result := FileAccess.open("res://LICENSE", FileAccess.READ).get_as_text()
	
	result += "\n" + Engine.get_license_text()
	result += "\nGodot Engine also uses third-party libraries, 
the next list includes the licensed files and their respective licenses:\n"

	for copyright in Engine.get_copyright_info():
		result += "Name: %s, parts:\n" % copyright["name"]
		for part in copyright["parts"]:
			result += "- files: %s
- copyright: %s
- license: %s

" % [", ".join(part["files"]), ", ".join(part["copyright"]), part["license"]]

	result += "Now the actual licenses texts:\n"
	
	var license_dict := Engine.get_license_info()
	for license_name in license_dict:
		result += "Name: %s, contents:\n%s\n" % [license_name, license_dict[license_name]]
	
	licensing.show()
	licensing.text = result
	
	
func next_text() -> void:
	current_text += 1
	if current_text >= texts.size() + 1:
		exit()
		return
	else:
		await Global.fade_out()
	display_text()
	await Global.fade_in()
	
func exit() -> void:
	get_tree().paused = true
	Global.music_fade_out()
	await Global.fade_out()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	Global.hide_fade()
	Global.change_scene(Global.get_initial_scene())
