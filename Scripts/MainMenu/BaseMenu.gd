extends Node2D

var current_menu: Node2D

@onready var selector: ColorRect = $Selector
var selector_option := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	# Disable every menu when starting up
	for menu: Node in get_children().filter(func(x: Node) -> bool: return x.is_in_group("menu")):
		enable_menu(menu, false)
	
	set_menu(%MenuMain)

func _process(_delta: float) -> void:
	if selector.is_processing():
		if Input.is_action_just_pressed("Down"):
			selector_option = mini(selector_option + 1, \
				current_menu.options.size() - 1)
			move_selector(selector_option)
			
		if Input.is_action_just_pressed("Up"):
			selector_option = maxi(selector_option - 1, 0)
			move_selector(selector_option)
		
	if Global.any_action_button_pressed():
		current_menu.menu_select(selector_option)
	
func enable_menu(menu: Node2D, flag: bool) -> void:
	menu.visible = flag
	menu.set_process(flag)
	menu.set_physics_process(flag)
	menu.set_process_input(flag)

func set_menu(menu: Node2D) -> void:
	var prev_menu := current_menu
	selector.visible = false
		
	current_menu = menu
	if prev_menu: prev_menu.menu_exit()
	current_menu.menu_enter()
	
	await get_tree().process_frame
	
	if prev_menu: enable_menu(prev_menu, false)
	enable_menu(current_menu, true)
	
	if current_menu.options.size() > 0:
		selector.visible = true
		selector.set_process(true)
		selector_option = 0
		move_selector(0)
	else:
		# Hide the selector in case if the menu doesn't have options
		selector.set_process(false)
	
func move_selector(option: int) -> void:
	var control_option: Node = current_menu.options[option]
	selector.global_position = control_option.global_position + Vector2(-16, 0)
	
func change_scene(scene: PackedScene) -> void:
	get_tree().paused = true
	
	Global.music_fade_out()
	await Global.fade_out()
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	Global.change_scene(scene)
