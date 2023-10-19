extends Node2D

var current_menu: Node2D

@onready var selector: ColorRect = $Selector
var selector_option := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	Global.hide_fade()
	
	# Disable every menu when starting up
	for menu in get_children().filter(func(x): return x.is_in_group("menu")):
		enable_menu(menu, false)
	
	set_menu($MenuMain)
	Global.play_music(preload("res://Audio/Soundtrack/MainMenu.ogg"))

func _process(_delta: float) -> void:
	if selector.visible:
		if Input.is_action_just_pressed("Down"):
			selector_option = min(selector_option + 1, \
				current_menu.options.size() - 1)
			move_selector(selector_option)
			
		if Input.is_action_just_pressed("Up"):
			selector_option = max(selector_option - 1, 0)
			move_selector(selector_option)
		
	if Input.is_action_just_pressed("B") \
		or Input.is_action_just_pressed("A") \
		or Input.is_action_just_pressed("Start"):
			current_menu.menu_select(selector_option)
	
func enable_menu(menu: Node2D, flag: bool) -> void:
	menu.visible = flag
	menu.set_process(flag)
	menu.set_physics_process(flag)
	menu.set_process_input(flag)

func set_menu(menu: Node2D) -> void:
	if current_menu:
		enable_menu(current_menu, false)
		current_menu.menu_exit()
		
	current_menu = menu
	enable_menu(current_menu, true)
	current_menu.menu_enter()
	
	if current_menu.options.size() > 0:
		selector.visible = true
		selector_option = 0
		move_selector(0)
	else:
		# Hide the selector in case if the menu doesn't have options 
		selector.visible = false
	
func move_selector(option: int) -> void:
	var control_option = current_menu.options[option]
	selector.global_position = control_option.global_position + Vector2(-16, 0)
	
func change_scene(scene: PackedScene) -> void:
	get_tree().paused = true
	
	Global.music_fade_out()
	Global.fade_out()
	await Global.fade_end
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	Global.change_scene(scene)
