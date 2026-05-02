extends Control

var font_title: Font
var font_text: Font

var title_pos = Vector2.ZERO

func _ready():
	font_title = load("res://assets/Shikakufuto_Free.ttf")
	font_text = load("res://assets/BestTen-CRT.otf")
	
	# Set theme fonts
	var title = $CenterContainer/VBoxContainer/TitleContainer/Title
	title.add_theme_font_override("normal_font", font_title)
	title_pos = title.position
	
	var play_btn = $CenterContainer/VBoxContainer/ButtonContainer/PlayButton
	play_btn.add_theme_font_override("font", font_title)
	
	# Set colors using GameConstants (class_name)
	title.add_theme_color_override("default_color", GameConstants.COLOR_FG)
	
	play_btn.add_theme_color_override("font_color", GameConstants.COLOR_DANGER)
	play_btn.add_theme_color_override("font_hover_color", GameConstants.COLOR_DANGER)
	play_btn.add_theme_color_override("font_pressed_color", GameConstants.COLOR_DANGER.darkened(0.4))
	play_btn.add_theme_color_override("font_focus_color", GameConstants.COLOR_DANGER)
	
	# Connect signals
	play_btn.pressed.connect(_on_play_pressed)
	play_btn.mouse_entered.connect(func(): _update_button_style(play_btn, true))
	play_btn.mouse_exited.connect(func(): _update_button_style(play_btn, false))
	play_btn.button_down.connect(func(): _on_button_down(play_btn))
	play_btn.button_up.connect(func(): _on_button_up(play_btn))
	
	# Initial style
	play_btn.pivot_offset = play_btn.size / 2

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _update_button_style(btn: Button, hover: bool):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hover:
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.2)
	else:
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)

func _on_button_down(btn: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05)
	tween.tween_property(btn, "self_modulate", Color(0.5, 0.5, 0.5), 0.05)

func _on_button_up(btn: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.1, 1.1) if btn.is_hovered() else Vector2(1.0, 1.0)
	tween.tween_property(btn, "scale", target_scale, 0.1)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.1)

func _process(_delta):
	# Update pivot offset for correct scaling
	var play_btn = $CenterContainer/VBoxContainer/ButtonContainer/PlayButton
	play_btn.pivot_offset = play_btn.size / 2
	
	# Subtle floating animation for the title
	var title = $CenterContainer/VBoxContainer/TitleContainer/Title
	title.position.y = title_pos.y + sin(Time.get_ticks_msec() * 0.002) * 8.0
	
	# Update blur shader uniforms to track actual element positions
	_update_blur_regions(title, play_btn)

func _update_blur_regions(title: Control, play_btn: Control):
	var blur_rect = $EdgeBlur
	if not blur_rect or not blur_rect.material:
		return
	
	var mat = blur_rect.material as ShaderMaterial
	var vp_size = get_viewport_rect().size
	if vp_size.x == 0 or vp_size.y == 0:
		return
	
	# Title: get global rect and convert to UV (0..1)
	var title_container = $CenterContainer/VBoxContainer/TitleContainer
	var t_rect = title_container.get_global_rect()
	var t_center = Vector2(
		(t_rect.position.x + t_rect.size.x * 0.5) / vp_size.x,
		(t_rect.position.y + t_rect.size.y * 0.5) / vp_size.y
	)
	var t_size = Vector2(
		(t_rect.size.x + 60.0) / vp_size.x,  # padding
		(t_rect.size.y + 40.0) / vp_size.y
	)
	mat.set_shader_parameter("title_center", t_center)
	mat.set_shader_parameter("title_size", t_size)
	
	# Button: get global rect and convert to UV (0..1)
	var b_rect = play_btn.get_global_rect()
	var b_center = Vector2(
		(b_rect.position.x + b_rect.size.x * 0.5) / vp_size.x,
		(b_rect.position.y + b_rect.size.y * 0.5) / vp_size.y
	)
	var b_size = Vector2(
		(b_rect.size.x + 60.0) / vp_size.x,  # padding
		(b_rect.size.y + 30.0) / vp_size.y
	)
	mat.set_shader_parameter("button_center", b_center)
	mat.set_shader_parameter("button_size", b_size)
