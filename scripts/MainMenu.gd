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
	
	var settings_btn = $CenterContainer/VBoxContainer/ButtonContainer/SettingsButton
	settings_btn.add_theme_font_override("font", font_title)
	
	# Settings UI elements
	var settings_label = $SettingsLayer/CenterContainer/VBoxContainer/Label
	settings_label.add_theme_font_override("font", font_title)
	
	var crt_check = $SettingsLayer/CenterContainer/VBoxContainer/CRTCheck
	crt_check.add_theme_font_override("font", font_title)
	crt_check.button_pressed = Config.crt_enabled
	
	var back_btn = $SettingsLayer/CenterContainer/VBoxContainer/BackButton
	back_btn.add_theme_font_override("font", font_title)
	
	# Set colors using GameConstants (class_name)
	title.add_theme_color_override("default_color", GameConstants.COLOR_FG)
	
	for btn in [play_btn, settings_btn, back_btn]:
		btn.add_theme_color_override("font_color", GameConstants.COLOR_FG)
		btn.add_theme_color_override("font_hover_color", GameConstants.COLOR_FG)
		btn.add_theme_color_override("font_pressed_color", GameConstants.COLOR_GHOST)
		btn.add_theme_color_override("font_focus_color", GameConstants.COLOR_FG)
		
		# Connect signals
		if btn != back_btn or not btn.pressed.is_connected(_on_back_pressed):
			btn.mouse_entered.connect(func(): _update_button_style(btn, true))
			btn.mouse_exited.connect(func(): _update_button_style(btn, false))
			btn.button_down.connect(func(): _on_button_down(btn))
			btn.button_up.connect(func(): _on_button_up(btn))
	
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	crt_check.toggled.connect(_on_crt_toggled)
	
	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)
	
	# Initial style
	play_btn.pivot_offset = play_btn.size / 2
	settings_btn.pivot_offset = settings_btn.size / 2
	back_btn.pivot_offset = back_btn.size / 2

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed():
	$SettingsLayer.visible = true

func _on_back_pressed():
	$SettingsLayer.visible = false

func _on_crt_toggled(enabled: bool):
	Config.crt_enabled = enabled

func _update_shader_visibility(enabled: bool):
	if has_node("EdgeBlur"):
		$EdgeBlur.visible = enabled

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
	tween.tween_property(btn, "self_modulate", Color(0.85, 0.85, 0.85), 0.05)

func _on_button_up(btn: Button):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.1, 1.1) if btn.is_hovered() else Vector2(1.0, 1.0)
	tween.tween_property(btn, "scale", target_scale, 0.1)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.1)

func _process(_delta):
	# Update pivot offsets
	for btn in [$CenterContainer/VBoxContainer/ButtonContainer/PlayButton, 
				$CenterContainer/VBoxContainer/ButtonContainer/SettingsButton,
				$SettingsLayer/CenterContainer/VBoxContainer/BackButton]:
		btn.pivot_offset = btn.size / 2
	
	# Subtle floating animation for the title
	var title = $CenterContainer/VBoxContainer/TitleContainer/Title
	title.position.y = title_pos.y + sin(Time.get_ticks_msec() * 0.002) * 8.0
	
	# Update blur shader uniforms
	_update_blur_regions(title, $CenterContainer/VBoxContainer/ButtonContainer/PlayButton)

func _update_blur_regions(title: Control, play_btn: Control):
	var blur_rect = $EdgeBlur
	if not blur_rect or not blur_rect.material or not blur_rect.visible:
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
