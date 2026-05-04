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
	
	# Reset font overrides for length/time to default
	length_label.remove_theme_font_override("font")
	time_label.remove_theme_font_override("font")
	length_label.remove_theme_font_size_override("font_size")
	time_label.remove_theme_font_size_override("font_size")



func _update_shader_visibility(enabled: bool):
	if edge_blur and edge_blur.material:
		edge_blur.material.set_shader_parameter("crt_enabled", enabled)
	if edge_blur:
		edge_blur.visible = true

func _process(delta):
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
	
	# Format time: MM:SS.mmm
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	var milliseconds = int((game_time - int(game_time)) * 1000)
	time_label.text = "TIME: %02d:%02d.%03d" % [minutes, seconds, milliseconds]

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
