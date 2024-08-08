extends Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	Global.play_music(preload("res://Audio/Soundtrack/TitleScreen.ogg"))
	
	$BeforeFlash.visible = true
	$AfterFlash.visible = false
	
	if Global.is_widescreen():
		var color_rects: Array[ColorRect] = \
			[$BeforeFlash/ColorRect, $AfterFlash/ColorRect2]
		for cr in color_rects:
			cr.size.x = Global.get_content_size().x
			cr.position.x = \
				-(Global.get_content_size().x - Global.get_default_resolution().x) / 2
	
func _process(_delta: float) -> void:
	if Global.any_action_button_pressed():
		if not $AfterFlash.visible:
			do_flash()
		else:
			leave()
			
func _on_flash_timer_timeout() -> void:
	do_flash()
	
func do_flash() -> void:
	if not $AfterFlash.visible and not Global.is_fading():
		await Global.fade_out(Global.FadeColor.WHITE)
		
		$BeforeFlash.visible = false
		$AfterFlash.visible = true
		Global.fade_in(Global.FadeColor.WHITE)
		
func leave() -> void:
	if not Global.is_fading():
		get_tree().paused = true
		
		Global.music_fade_out()
		await Global.fade_out(Global.FadeColor.BLACK)
		
		await get_tree().create_timer(0.5).timeout
		
		get_tree().paused = false
		Global.change_scene(preload("res://Scenes/MainMenu/MainMenu.tscn"))
