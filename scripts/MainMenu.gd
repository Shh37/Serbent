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
	
	var skins_btn = $CenterContainer/VBoxContainer/ButtonContainer/SkinsButton
	skins_btn.add_theme_font_override("font", font_title)
	
	# Settings UI elements
	var settings_label = $SettingsLayer/CenterContainer/VBoxContainer/Label
	settings_label.add_theme_font_override("font", font_title)
	settings_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	
	var crt_label = $SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/Label
	crt_label.add_theme_font_override("font", font_title)
	crt_label.add_theme_color_override("font_color", GameConstants.COLOR_FG) # Made more prominent
	
	var crt_on_btn = $SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOn
	var crt_off_btn = $SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOff
	
	var beta_label = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/Label
	beta_label.add_theme_font_override("font", font_title)
	beta_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	
	var beta_on_btn = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOn
	var beta_off_btn = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOff
	
	var back_btn = $SettingsLayer/CenterContainer/VBoxContainer/BackButton
	back_btn.add_theme_font_override("font", font_title)
	
	# Skin Layer UI elements
	var skin_label = $SkinLayer/CenterContainer/VBoxContainer/Label
	skin_label.add_theme_font_override("font", font_title)
	skin_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	
	var skin_back_btn = $SkinLayer/CenterContainer/VBoxContainer/BackButton
	skin_back_btn.add_theme_font_override("font", font_title)
	
	# Color selection UI
	var color_label = $SkinLayer/CenterContainer/VBoxContainer/ColorContainer/ColorName
	color_label.add_theme_font_override("font", font_title)
	
	var prev_color_btn = $SkinLayer/CenterContainer/VBoxContainer/ColorContainer/PrevColor
	var next_color_btn = $SkinLayer/CenterContainer/VBoxContainer/ColorContainer/NextColor
	
	# Pattern selection UI
	var pattern_label = $SkinLayer/CenterContainer/VBoxContainer/PatternContainer/PatternName
	pattern_label.add_theme_font_override("font", font_title)
	
	var prev_pattern_btn = $SkinLayer/CenterContainer/VBoxContainer/PatternContainer/PrevPattern
	var next_pattern_btn = $SkinLayer/CenterContainer/VBoxContainer/PatternContainer/NextPattern
	
	# Set colors using GameConstants (class_name)
	title.add_theme_color_override("default_color", GameConstants.COLOR_FG)
	
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	skins_btn.pressed.connect(_on_skins_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	skin_back_btn.pressed.connect(_on_skin_back_pressed)
	
	for btn in [play_btn, settings_btn, skins_btn, back_btn, skin_back_btn, crt_on_btn, crt_off_btn, beta_on_btn, beta_off_btn]:
		btn.add_theme_font_override("font", font_title)
		btn.add_theme_color_override("font_color", GameConstants.COLOR_FG)
		btn.add_theme_color_override("font_hover_color", GameConstants.COLOR_FG)
		btn.add_theme_color_override("font_pressed_color", GameConstants.COLOR_GHOST)
		btn.add_theme_color_override("font_focus_color", GameConstants.COLOR_FG)
		
		# Connect signals
		btn.mouse_entered.connect(func(): _update_button_style(btn, true))
		btn.mouse_exited.connect(func(): _update_button_style(btn, false))
		btn.button_down.connect(func(): _on_button_down(btn))
		btn.button_up.connect(func(): _on_button_up(btn))
	
	crt_on_btn.pressed.connect(func(): _on_crt_toggle_pressed(true))
	crt_off_btn.pressed.connect(func(): _on_crt_toggle_pressed(false))
	beta_on_btn.pressed.connect(func(): _on_beta_toggle_pressed(true))
	beta_off_btn.pressed.connect(func(): _on_beta_toggle_pressed(false))
	
	prev_color_btn.pressed.connect(func(): _on_color_cycle_pressed(-1))
	next_color_btn.pressed.connect(func(): _on_color_cycle_pressed(1))
	
	prev_pattern_btn.pressed.connect(func(): _on_pattern_cycle_pressed(-1))
	next_pattern_btn.pressed.connect(func(): _on_pattern_cycle_pressed(1))
	
	for btn in [prev_color_btn, next_color_btn, prev_pattern_btn, next_pattern_btn]:
		btn.add_theme_font_override("font", font_title)
		btn.add_theme_color_override("font_color", GameConstants.COLOR_FG)
		btn.add_theme_color_override("font_hover_color", GameConstants.COLOR_SNAKE)
		btn.add_theme_color_override("font_pressed_color", GameConstants.COLOR_GHOST)
		btn.mouse_entered.connect(func(): _update_button_style(btn, true))
		btn.mouse_exited.connect(func(): _update_button_style(btn, false))
		btn.button_down.connect(func(): _on_button_down(btn))
		btn.button_up.connect(func(): _on_button_up(btn))

	# Sync initial appearance
	_update_appearance_display()
	
	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	_update_crt_buttons_style(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)
	Config.crt_changed.connect(_update_crt_buttons_style)
	
	_update_beta_buttons_style(Config.beta_upgrades_enabled)
	Config.beta_upgrades_changed.connect(_update_beta_buttons_style)
	
	# Initial style
	for btn in [play_btn, settings_btn, back_btn, crt_on_btn, crt_off_btn, beta_on_btn, beta_off_btn]:
		btn.pivot_offset = btn.size / 2

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed():
	$SettingsLayer.visible = true

func _on_skins_pressed():
	$SkinLayer.visible = true

func _on_back_pressed():
	$SettingsLayer.visible = false

func _on_skin_back_pressed():
	$SkinLayer.visible = false

func _on_crt_toggle_pressed(enabled: bool):
	Config.crt_enabled = enabled

func _on_beta_toggle_pressed(enabled: bool):
	Config.beta_upgrades_enabled = enabled

func _update_beta_buttons_style(enabled: bool):
	var beta_on_btn = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOn
	var beta_off_btn = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOff
	
	if enabled:
		beta_on_btn.add_theme_color_override("font_color", GameConstants.COLOR_SNAKE) # Active green
		beta_off_btn.add_theme_color_override("font_color", GameConstants.COLOR_GHOST) # Inactive gray
	else:
		beta_on_btn.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
		beta_off_btn.add_theme_color_override("font_color", GameConstants.COLOR_DANGER) # Active red

func _update_crt_buttons_style(enabled: bool):
	var crt_on_btn = $SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOn
	var crt_off_btn = $SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOff
	
	if enabled:
		crt_on_btn.add_theme_color_override("font_color", GameConstants.COLOR_SNAKE) # Active green
		crt_off_btn.add_theme_color_override("font_color", GameConstants.COLOR_GHOST) # Inactive gray
	else:
		crt_on_btn.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
		crt_off_btn.add_theme_color_override("font_color", GameConstants.COLOR_DANGER) # Active red

func _on_color_cycle_pressed(dir: int):
	var colors = GameConstants.SkinColor.values()
	var current_idx = colors.find(Config.selected_color)
	
	var next_idx = current_idx
	for i in range(colors.size()):
		next_idx = (next_idx + dir + colors.size()) % colors.size()
		if colors[next_idx] in Config.unlocked_colors:
			break
			
	Config.selected_color = colors[next_idx] as GameConstants.SkinColor
	_update_appearance_display()

func _on_pattern_cycle_pressed(dir: int):
	var patterns = GameConstants.SkinPattern.values()
	var current_idx = patterns.find(Config.selected_pattern)
	
	var next_idx = current_idx
	for i in range(patterns.size()):
		next_idx = (next_idx + dir + patterns.size()) % patterns.size()
		if patterns[next_idx] in Config.unlocked_patterns:
			break
			
	Config.selected_pattern = patterns[next_idx] as GameConstants.SkinPattern
	_update_appearance_display()

func _update_appearance_display():
	var color_name_label = $SkinLayer/CenterContainer/VBoxContainer/ColorContainer/ColorName
	var pattern_name_label = $SkinLayer/CenterContainer/VBoxContainer/PatternContainer/PatternName
	
	var c_type = Config.selected_color
	var p_type = Config.selected_pattern
	
	var color_names = {
		GameConstants.SkinColor.BASIC: "BASIC",
		GameConstants.SkinColor.MINT: "MINT",
		GameConstants.SkinColor.OLIVE: "OLIVE",
		GameConstants.SkinColor.MOSS: "MOSS",
		GameConstants.SkinColor.LIME: "LIME",
		GameConstants.SkinColor.EMERALD: "EMERALD"
	}
	color_name_label.text = color_names.get(c_type, "UNKNOWN")
	
	var pattern_names = {
		GameConstants.SkinPattern.SOLID: "SOLID",
		GameConstants.SkinPattern.STRIPE11: "STRIPE 1-1",
		GameConstants.SkinPattern.STRIPE12: "STRIPE 1-2",
		GameConstants.SkinPattern.STRIPE21: "STRIPE 2-1",
		GameConstants.SkinPattern.STRIPE22: "STRIPE 2-2",
		GameConstants.SkinPattern.GRADIENT: "GRADIENT"
	}
	pattern_name_label.text = pattern_names.get(p_type, "UNKNOWN")
	
	var base_color = GameConstants.SKIN_COLORS[c_type]
	color_name_label.add_theme_color_override("font_color", base_color)
	
	# For pattern label, maybe use the darker color
	var darker_color = base_color.darkened(0.3)
	pattern_name_label.add_theme_color_override("font_color", darker_color)
	
	# Visual feedback on background
	var bg = $MenuBackground
	if bg.has_method("set_snake_color"):
		bg.set_snake_color(base_color)

func _update_shader_visibility(enabled: bool):
	# Update main menu edge blur
	var blur_rect = $EdgeBlur
	if blur_rect and blur_rect.material:
		blur_rect.material.set_shader_parameter("crt_enabled", enabled)
	if blur_rect:
		blur_rect.visible = true
		
	# Update settings background blur
	var settings_blur = $SettingsLayer/ColorRect
	if settings_blur and settings_blur.material:
		settings_blur.material.set_shader_parameter("crt_enabled", enabled)
		
	# Update skin background blur
	var skin_blur = $SkinLayer/ColorRect
	if skin_blur and skin_blur.material:
		skin_blur.material.set_shader_parameter("crt_enabled", enabled)

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
				$CenterContainer/VBoxContainer/ButtonContainer/SkinsButton,
				$CenterContainer/VBoxContainer/ButtonContainer/SettingsButton,
				$SettingsLayer/CenterContainer/VBoxContainer/BackButton,
				$SkinLayer/CenterContainer/VBoxContainer/BackButton,
				$SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOn,
				$SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOff,
				$SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOn,
				$SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOff,
				$SkinLayer/CenterContainer/VBoxContainer/ColorContainer/PrevColor,
				$SkinLayer/CenterContainer/VBoxContainer/ColorContainer/NextColor,
				$SkinLayer/CenterContainer/VBoxContainer/PatternContainer/PrevPattern,
				$SkinLayer/CenterContainer/VBoxContainer/PatternContainer/NextPattern]:
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
