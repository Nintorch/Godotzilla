extends Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	Global.play_music(preload("res://Audio/Soundtrack/TitleScreen.ogg"))
	
	$BeforeFlash.visible = true
	$AfterFlash.visible = false
	
func _process(_delta: float) -> void:
	if Global.any_action_button_pressed():
		if not $AfterFlash.visible:
			do_flash()
		else:
			leave()
			
func _on_flash_timer_timeout() -> void:
	do_flash()
	
func do_flash() -> void:
	if not $AfterFlash.visible and not Global.fading:
		Global.fade_out(Global.FADE_WHITE)
		await Global.fade_end
		
		$BeforeFlash.visible = false
		$AfterFlash.visible = true
		Global.fade_in(Global.FADE_WHITE)
		
func leave() -> void:
	if not Global.fading:
		get_tree().paused = true
		
		Global.music_fade_out()
		Global.fade_out(Global.FADE_BLACK)
		await Global.fade_end
		
		await get_tree().create_timer(0.5).timeout
		
		get_tree().paused = false
		Global.change_scene(preload("res://Scenes/MainMenu.tscn"))
