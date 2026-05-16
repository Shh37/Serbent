extends CanvasLayer

@onready var length_label = $Control/MarginContainer/HBoxContainer/LengthLabel
@onready var time_label = $Control/MarginContainer/HBoxContainer/TimeLabel
@onready var edge_blur = $EdgeBlur

var snake: Node2D
var game_time = 0.0
var fx_tween: Tween

# Shader defaults
const DEFAULT_BLUR = 4.0
const DEFAULT_TINT = Color(0.1, 0.1, 0.1, 0.4)

var main_font: Font

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_font = load("res://assets/Shikakufuto_Free.ttf")
	# Make material unique to prevent parameter persistence across scene reloads
	if edge_blur and edge_blur.material:
		edge_blur.material = edge_blur.material.duplicate()
		# Reset to defaults immediately
		edge_blur.material.set_shader_parameter("blur_strength", DEFAULT_BLUR)
		edge_blur.material.set_shader_parameter("tint_color", DEFAULT_TINT)
		
	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)
	
	# Wait for the scene to be fully loaded to find the snake
	await get_tree().process_frame
	snake = get_tree().root.find_child("Snake", true, false)
	
	_setup_centering()


func _setup_centering():
	# Move Length/Time back to corners
	var container = $Control/MarginContainer
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 20)
	
	# Apply larger font size for HUD
	var target_font_size = 48
	if length_label.label_settings:
		length_label.label_settings.font_size = target_font_size
	else:
		length_label.add_theme_font_size_override("font_size", target_font_size)
		
	if time_label.label_settings:
		time_label.label_settings.font_size = target_font_size
	else:
		time_label.add_theme_font_size_override("font_size", target_font_size)



func _update_shader_visibility(enabled: bool):
	if edge_blur and edge_blur.material:
		edge_blur.material.set_shader_parameter("crt_enabled", enabled)
	if edge_blur:
		edge_blur.visible = true

func _process(delta):
	# Don't update when result screen is showing
	if is_result_showing:
		_update_result_button_pivots()
		return
	
	if snake and snake.is_reversing:
		update_ui() # Keep updating UI (like length) but skip timer
		return
		
	game_time += delta
	update_ui()
	_update_powerup_visuals()

func _update_powerup_visuals():
	if not (edge_blur and edge_blur.material): return
	
	if snake and not snake.active_powerups.is_empty():
		var mixed_color = Color(0,0,0,0)
		var mixed_blur = 0.0
		var total_alpha = 0.0
		var total_weight = 0.0
		
		for type in snake.active_powerups.keys():
			var time_left = snake.active_powerups[type]
			var base_color = Color.WHITE
			match type:
				GameConstants.PowerUpType.GHOST: base_color = GameConstants.COLOR_POWERUP_GHOST
				GameConstants.PowerUpType.TIME_STOP: base_color = GameConstants.COLOR_POWERUP_TIME
				GameConstants.PowerUpType.DOUBLE_GROWTH: base_color = GameConstants.COLOR_POWERUP_GROWTH
			
			base_color = base_color.darkened(0.5)
			var current_weight = 1.0
			
			if time_left <= 2.0:
				var blink_speed = 15.0
				current_weight = 0.7 + 0.3 * sin(game_time * blink_speed) # 0.4 to 1.0 (strong/weak)


				
			var current_alpha = 0.5 * current_weight
			
			mixed_color.r += base_color.r * current_alpha
			mixed_color.g += base_color.g * current_alpha
			mixed_color.b += base_color.b * current_alpha
			total_alpha += current_alpha
			
			mixed_blur += 3.0 * current_weight # powerup blur target is 3.0
			total_weight += current_weight
			
		var final_blur = DEFAULT_BLUR
		var num_powerups = snake.active_powerups.size()
		
		if total_alpha > 0:
			mixed_color.r /= total_alpha
			mixed_color.g /= total_alpha
			mixed_color.b /= total_alpha
			mixed_color.a = min(total_alpha, 0.6)
			
			var avg_weight = total_weight / num_powerups
			var avg_blur = mixed_blur / total_weight
			final_blur = lerp(DEFAULT_BLUR, avg_blur, avg_weight)
		else:
			mixed_color.a = 0.0
		
		# "Hold" the colored surround effect
		var mat = edge_blur.material as ShaderMaterial
		mat.set_shader_parameter("blur_strength", final_blur)
		mat.set_shader_parameter("tint_color", mixed_color)
	elif not fx_tween or not fx_tween.is_running():
		# Reset to defaults if no FX tween is active
		var mat = edge_blur.material as ShaderMaterial
		mat.set_shader_parameter("blur_strength", DEFAULT_BLUR)
		mat.set_shader_parameter("tint_color", DEFAULT_TINT)



@onready var powerup_list = $Control/MarginContainer/HBoxContainer # Or create a new one

func update_ui():
	if snake:
		length_label.text = "LENGTH: %d" % snake.body.size()
		_update_powerups_ui()
	
	# Format time: MM:SS.cc (centiseconds)
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	var centiseconds = int((game_time - int(game_time)) * 100)
	time_label.text = "TIME: %02d:%02d.%02d" % [minutes, seconds, centiseconds]

func _update_powerups_ui():
	# For simplicity, we'll clear and rebuild a small list or just use labels
	# But we don't have many nodes. Let's just use a simple approach:
	# Check if snake has powerups and show them in a specific color.
	
	# Actually, I'll just use the existing HBox and add/remove labels as needed?
	# Better to have a dedicated container. I'll search for it or create it.
	var pu_container = $Control.get_node_or_null("PowerUpContainer")
	if not pu_container:
		pu_container = VBoxContainer.new()
		pu_container.name = "PowerUpContainer"
		$Control.add_child(pu_container)
		pu_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 20)
		pu_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		pu_container.position.y = 80

	
	# Clear existing
	for child in pu_container.get_children():
		child.queue_free()
		
	if not snake: return
	
	for type in snake.active_powerups.keys():
		var time_left = snake.active_powerups[type]
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var type_name = ""
		var color = Color.WHITE
		match type:
			GameConstants.PowerUpType.GHOST:
				type_name = "PHANTOM"
				color = GameConstants.COLOR_POWERUP_GHOST # Now Purple

			GameConstants.PowerUpType.TIME_STOP:
				type_name = "TIME STOP"
				color = GameConstants.COLOR_POWERUP_TIME
			GameConstants.PowerUpType.DOUBLE_GROWTH:
				type_name = "DOUBLE GROWTH"
				color = GameConstants.COLOR_POWERUP_GROWTH
		
		label.text = "%s: %.1fs" % [type_name, time_left]
		label.add_theme_color_override("font_color", color)
		if main_font:
			label.add_theme_font_override("font", main_font)
		label.add_theme_font_size_override("font_size", 24)
		
		if time_left <= 2.0:
			# Blink effect
			var blink_speed = 15.0
			label.modulate.a = 0.2 + 0.8 * (sin(game_time * blink_speed) * 0.5 + 0.5)

		else:
			label.modulate.a = 1.0

		
		pu_container.add_child(label)



func play_screen_fx(target_blur: float, target_tint: Color, duration: float) -> Tween:
	if not (edge_blur and edge_blur.material):
		return null
		
	if fx_tween:
		fx_tween.kill()
		
	var blur_mat = edge_blur.material as ShaderMaterial
	fx_tween = create_tween()
	
	var current_blur = blur_mat.get_shader_parameter("blur_strength")
	var current_tint = blur_mat.get_shader_parameter("tint_color")
	
	# Intensify (Fast pop: 20% of duration)
	fx_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fx_tween.tween_method(func(v): blur_mat.set_shader_parameter("blur_strength", v), current_blur, target_blur, duration * 0.2)
	fx_tween.parallel().tween_method(func(v): blur_mat.set_shader_parameter("tint_color", v), current_tint, target_tint, duration * 0.2)
	
	# Fade back to ABSOLUTE defaults (not current state)
	fx_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fx_tween.tween_method(func(v): blur_mat.set_shader_parameter("blur_strength", v), target_blur, DEFAULT_BLUR, duration * 0.8)
	fx_tween.parallel().tween_method(func(v): blur_mat.set_shader_parameter("tint_color", v), target_tint, DEFAULT_TINT, duration * 0.8)
	
	return fx_tween

# ============================================================
# Result Screen
# ============================================================
var result_layer: CanvasLayer
var result_buttons: Array[Button] = []
var is_result_showing = false

func show_result_screen(final_length: int, survival_time: float, longest_length: int, total_points: int):
	if is_result_showing:
		return
	is_result_showing = true
	result_buttons.clear()
	
	# Create the result overlay layer
	result_layer = CanvasLayer.new()
	result_layer.name = "ResultLayer"
	result_layer.layer = 10
	result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(result_layer)
	
	# Blur background
	var blur_bg = ColorRect.new()
	blur_bg.name = "BlurBG"
	var blur_shader = load("res://shaders/ui_blur.gdshader")
	var blur_mat = ShaderMaterial.new()
	blur_mat.shader = blur_shader
	blur_mat.set_shader_parameter("blur_amount", 5.0)
	blur_mat.set_shader_parameter("tint_color", Color(0.0823529, 0.0823529, 0.0823529, 0.6))
	blur_mat.set_shader_parameter("crt_enabled", Config.crt_enabled)
	blur_bg.material = blur_mat
	result_layer.add_child(blur_bg)
	blur_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Center container
	var center = CenterContainer.new()
	result_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Main Content VBox
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 35)
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(content_vbox)
	
	# 1. Header
	var header = Label.new()
	header.text = "RESULTS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", main_font)
	header.add_theme_font_size_override("font_size", 80)
	header.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	content_vbox.add_child(header)
	
	# Separator
	content_vbox.add_child(_create_separator())
	
	# 2. Stats Container
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 15)
	content_vbox.add_child(stats_vbox)
	
	# Format survival time
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	var centiseconds = int((survival_time - int(survival_time)) * 100)
	var time_str = "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
	
	# Horizontal Stat Rows
	_add_result_row(stats_vbox, "SURVIVAL TIME", time_str, 28, 44, GameConstants.COLOR_POINT)
	_add_result_row(stats_vbox, "LONGEST LENGTH", str(longest_length), 28, 44, GameConstants.COLOR_POINT)
	_add_result_row(stats_vbox, "FINAL LENGTH", str(final_length), 22, 28, GameConstants.COLOR_FG)
	_add_result_row(stats_vbox, "POINTS", str(total_points), 22, 28, GameConstants.COLOR_FG)
	
	# Separator
	content_vbox.add_child(_create_separator())
	
	# 3. Action Buttons
	var action_vbox = VBoxContainer.new()
	action_vbox.add_theme_constant_override("separation", 15)
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_child(action_vbox)
	
	var retry_btn = _create_result_button("RETRY", 54)
	retry_btn.pressed.connect(_on_retry_pressed)
	action_vbox.add_child(retry_btn)
	result_buttons.append(retry_btn)
	
	var title_btn = _create_result_button("MAIN MENU", 36)
	title_btn.pressed.connect(_on_title_pressed)
	action_vbox.add_child(title_btn)
	result_buttons.append(title_btn)
	
	# Animate entrance
	_animate_result_entrance(content_vbox, blur_mat)

func _add_result_row(parent: Control, label_text: String, value_text: String, label_size: int, value_size: int, value_color: Color):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(550, 0)
	hbox.add_theme_constant_override("separation", 40)
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", main_font)
	label.add_theme_font_size_override("font_size", label_size)
	label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_override("font", main_font)
	value.add_theme_font_size_override("font_size", value_size)
	value.add_theme_color_override("font_color", value_color)
	hbox.add_child(value)

func _create_separator() -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(550, 2)
	sep.color = GameConstants.COLOR_GHOST
	sep.color.a = 0.25
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return sep

func _create_result_button(text: String, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", main_font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	btn.add_theme_color_override("font_hover_color", GameConstants.COLOR_FG)
	btn.add_theme_color_override("font_pressed_color", GameConstants.COLOR_GHOST)
	btn.add_theme_color_override("font_focus_color", GameConstants.COLOR_FG)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	btn.mouse_entered.connect(func(): _animate_result_btn(btn, true))
	btn.mouse_exited.connect(func(): _animate_result_btn(btn, false))
	btn.button_down.connect(func(): _on_result_btn_down(btn))
	btn.button_up.connect(func(): _on_result_btn_up(btn))
	
	return btn

func _animate_result_btn(btn: Button, hover: bool):
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hover:
		tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.2)
	else:
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)

func _on_result_btn_down(btn: Button):
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.05)
	tween.tween_property(btn, "self_modulate", Color(0.8, 0.8, 0.8), 0.05)

func _on_result_btn_up(btn: Button):
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.08, 1.08) if btn.is_hovered() else Vector2(1.0, 1.0)
	tween.tween_property(btn, "scale", target_scale, 0.1)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.1)

func _animate_result_entrance(container: Control, blur_mat: ShaderMaterial):
	container.modulate.a = 0
	
	# Initial blur state
	blur_mat.set_shader_parameter("blur_amount", 0.0)
	
	# Wait one frame to let the container finish layout and find the centered Y
	await get_tree().process_frame
	
	var target_y = container.position.y
	container.position.y += 80 # Offset for slide up
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# UI Animation
	tween.tween_property(container, "modulate:a", 1.0, 0.5)
	tween.tween_property(container, "position:y", target_y, 0.6)
	
	# Blur Animation
	tween.tween_property(blur_mat, "shader_parameter/blur_amount", 5.0, 0.6)


func _update_result_button_pivots():
	for btn in result_buttons:
		if is_instance_valid(btn):
			btn.pivot_offset = btn.size / 2
	
	# Also update main content vbox pivot for scale animation
	var center = result_layer.get_node_or_null("CenterContainer")
	if center:
		var vbox = center.get_child(0)
		if vbox:
			vbox.pivot_offset = vbox.size / 2

func _on_retry_pressed():
	get_tree().paused = false
	is_result_showing = false
	result_buttons.clear()
	get_tree().reload_current_scene()

func _on_title_pressed():
	get_tree().paused = false
	is_result_showing = false
	result_buttons.clear()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
