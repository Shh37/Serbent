extends CanvasLayer

@onready var length_label = $Control/MarginContainer/HBoxContainer/LengthLabel
@onready var time_label = $Control/MarginContainer/HBoxContainer/TimeLabel
@onready var edge_blur = $EdgeBlur

var snake: Node2D
var game_time = 0.0
var fx_tween: Tween
var run_unlocked_skins = {
	"colors": [],
	"patterns": []
}
var flashed_length_unlock_thresholds = []
var flashed_time_unlock_thresholds = []
var dash_hint_label: Label
var dash_hint_idle_time = 0.0
var dash_hint_dismissed = false
var reverse_hint_idle_time = 0.0
var reverse_hint_dismissed = false
var was_snake_reversing = false
var dash_hint_target_visible = false
var dash_hint_tween: Tween
var hint_cycle_time = 0.0
var current_hint_key = ""

# Shader defaults
const DEFAULT_BLUR = 4.0
const DEFAULT_TINT = Color(0.1, 0.1, 0.1, 0.4)
const DASH_HINT_DELAY = 8.0
const REVERSE_HINT_DELAY = 8.0
const HINT_CYCLE_TIME = 4.5
const DASH_HINT_FADE_TIME = 0.25
const MENU_SHORTCUT_TRANSITION_TIME = 0.28

var main_font: Font
var hint_font: Font
var shortcut_transition_in_progress = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_font = load("res://assets/Shikakufuto_Free.ttf")
	hint_font = load("res://assets/BestTen-CRT.otf")
	# Make material unique to prevent parameter persistence across scene reloads
	if edge_blur and edge_blur.material:
		edge_blur.material = edge_blur.material.duplicate()
		# Reset to defaults immediately
		edge_blur.material.set_shader_parameter("blur_strength", DEFAULT_BLUR)
		edge_blur.material.set_shader_parameter("tint_color", DEFAULT_TINT)

	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)
	Config.language_changed.connect(func(_language):
		update_ui()
		_update_control_hint_text()
	)

	# Wait for the scene to be fully loaded to find the snake
	await get_tree().process_frame
	snake = get_tree().root.find_child("Snake", true, false)

	_setup_centering()
	_setup_dash_hint()


func _unhandled_key_input(event):
	if Config.is_shortcut_event(event, Config.ACTION_SHORTCUT_RETRY):
		get_viewport().set_input_as_handled()
		await _retry_from_shortcut()
	elif Config.is_shortcut_event(event, Config.ACTION_SHORTCUT_MAIN_MENU):
		get_viewport().set_input_as_handled()
		await _go_to_main_menu_from_shortcut()

func _retry_from_shortcut():
	if shortcut_transition_in_progress or result_exit_in_progress:
		return
	if is_result_showing:
		if not Config.can_retry_action():
			return
		shortcut_transition_in_progress = true
		await _play_result_shortcut_button_press(result_retry_button)
		await _on_retry_pressed()
		return

	if not Config.consume_retry_action():
		return
	shortcut_transition_in_progress = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _go_to_main_menu_from_shortcut():
	if shortcut_transition_in_progress or result_exit_in_progress:
		return
	if is_result_showing:
		shortcut_transition_in_progress = true
		await _play_result_shortcut_button_press(result_title_button)
		await _on_title_pressed()
		return

	shortcut_transition_in_progress = true
	get_tree().paused = false
	await _animate_main_menu_shortcut_transition()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _play_result_shortcut_button_press(btn: Button):
	if not btn or not is_instance_valid(btn):
		return
	btn.grab_focus()
	_on_result_btn_down(btn)
	await get_tree().create_timer(0.08, true).timeout

func _animate_main_menu_shortcut_transition():
	var transition_layer = CanvasLayer.new()
	transition_layer.name = "ShortcutTransitionLayer"
	transition_layer.layer = 20
	transition_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(transition_layer)

	var blur_bg = ColorRect.new()
	blur_bg.name = "ShortcutTransitionBlur"
	blur_bg.modulate.a = 0.0
	blur_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.add_child(blur_bg)
	blur_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var blur_shader = load("res://shaders/ui_blur.gdshader")
	var blur_mat: ShaderMaterial = null
	if blur_shader:
		blur_mat = ShaderMaterial.new()
		blur_mat.shader = blur_shader
		blur_mat.set_shader_parameter("blur_amount", 0.0)
		blur_mat.set_shader_parameter("tint_color", Color(0.0823529, 0.0823529, 0.0823529, 0.55))
		blur_mat.set_shader_parameter("crt_enabled", Config.crt_enabled)
		blur_bg.material = blur_mat

	var shade = ColorRect.new()
	shade.name = "ShortcutTransitionShade"
	shade.color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.62)
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blur_bg, "modulate:a", 1.0, MENU_SHORTCUT_TRANSITION_TIME)
	tween.tween_property(shade, "modulate:a", 1.0, MENU_SHORTCUT_TRANSITION_TIME)
	if blur_mat:
		tween.tween_property(blur_mat, "shader_parameter/blur_amount", 5.0, MENU_SHORTCUT_TRANSITION_TIME)

	await tween.finished

func _setup_centering():
	# Move Length/Time back to corners
	var container = $Control/MarginContainer
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 20)
	_prepare_hud_label_color(length_label)
	_prepare_hud_label_color(time_label)

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
		_set_dash_hint_visible(false)
		_update_result_button_pivots()
		return

	if snake and snake.is_reversing:
		update_ui() # Keep updating UI (like length) but skip timer
		_update_dash_hint(delta)
		return

	game_time += delta
	update_ui()
	_check_skin_unlocks()
	_update_powerup_visuals()
	_update_dash_hint(delta)

func _input(event):
	if not _is_ranking_dialog_open():
		return
	if not event is InputEventMouseButton:
		return

	var mouse_event = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	if ranking_name_input and is_instance_valid(ranking_name_input) and ranking_name_input.has_focus():
		if not ranking_name_input.get_global_rect().has_point(mouse_event.position):
			ranking_name_input.release_focus()

	if ranking_dialog_panel and is_instance_valid(ranking_dialog_panel):
		if not ranking_dialog_panel.get_global_rect().has_point(mouse_event.position):
			get_viewport().set_input_as_handled()
			_close_ranking_dialog()

func _setup_dash_hint():
	var control = $Control
	dash_hint_label = Label.new()
	dash_hint_label.name = "DashHintLabel"
	dash_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dash_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dash_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dash_hint_label.modulate.a = 0.0
	dash_hint_label.visible = false
	dash_hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 20)
	dash_hint_label.offset_left = 32
	dash_hint_label.offset_right = -32
	dash_hint_label.offset_top = -72
	dash_hint_label.offset_bottom = -28
	dash_hint_label.add_theme_font_override("font", hint_font)
	dash_hint_label.add_theme_font_size_override("font_size", 20)
	dash_hint_label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	_update_control_hint_text()
	control.add_child(dash_hint_label)

func _update_dash_hint(delta: float):
	if not dash_hint_label or is_result_showing:
		_set_dash_hint_visible(false)
		return
	if not snake:
		_set_dash_hint_visible(false)
		return
	if bool(snake.get("is_dead")):
		_set_dash_hint_visible(false)
		return

	var is_snake_reversing = bool(snake.get("is_reversing"))
	if is_snake_reversing and not was_snake_reversing:
		reverse_hint_dismissed = true
	was_snake_reversing = is_snake_reversing

	if snake.is_dashing:
		if not dash_hint_dismissed:
			reverse_hint_idle_time = 0.0
			hint_cycle_time = 0.0
		dash_hint_dismissed = true
		if not reverse_hint_dismissed:
			reverse_hint_idle_time += delta
			if reverse_hint_idle_time >= REVERSE_HINT_DELAY:
				hint_cycle_time += delta
				_update_control_hint_text("reverse_hint")
				_set_dash_hint_visible(true)
				return
		_set_dash_hint_visible(false)
		return
	if is_snake_reversing:
		_set_dash_hint_visible(false)
		return

	var due_hints = []
	if not dash_hint_dismissed:
		dash_hint_idle_time += delta
		if dash_hint_idle_time >= DASH_HINT_DELAY:
			due_hints.append("dash_hint")
	if dash_hint_dismissed and not reverse_hint_dismissed:
		reverse_hint_idle_time += delta
		if reverse_hint_idle_time >= REVERSE_HINT_DELAY:
			due_hints.append("reverse_hint")

	if due_hints.is_empty():
		current_hint_key = ""
		_set_dash_hint_visible(false)
		return

	hint_cycle_time += delta
	var hint_index = int(floor(hint_cycle_time / HINT_CYCLE_TIME)) % due_hints.size()
	_update_control_hint_text(due_hints[hint_index])
	_set_dash_hint_visible(true)

func _set_dash_hint_visible(should_show: bool):
	if not dash_hint_label:
		return
	if dash_hint_target_visible == should_show:
		return
	dash_hint_target_visible = should_show
	if dash_hint_tween:
		dash_hint_tween.kill()

	if should_show:
		dash_hint_label.visible = true

	dash_hint_tween = create_tween()
	dash_hint_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	dash_hint_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	dash_hint_tween.tween_property(dash_hint_label, "modulate:a", 0.78 if should_show else 0.0, DASH_HINT_FADE_TIME)
	if not should_show:
		dash_hint_tween.finished.connect(func():
			if dash_hint_label:
				dash_hint_label.visible = false
		)

func _update_control_hint_text(preferred_key: String = ""):
	if dash_hint_label:
		if not preferred_key.is_empty():
			current_hint_key = preferred_key
		var text_key = current_hint_key if not current_hint_key.is_empty() else "dash_hint"
		dash_hint_label.text = Config.tr_text(text_key)

func _check_skin_unlocks():
	if not snake:
		return

	var current_length = max(int(snake.max_length), snake.body.size())
	for unlock in Config.COLOR_UNLOCKS:
		var threshold = int(unlock.get("threshold", 0))
		if threshold <= 0:
			continue
		if current_length >= threshold and not (threshold in flashed_length_unlock_thresholds):
			flashed_length_unlock_thresholds.append(threshold)
			if Config.unlock_color(unlock.get("type")):
				run_unlocked_skins["colors"].append(unlock)
			_flash_unlock_condition_label(length_label)

	for unlock in Config.PATTERN_UNLOCKS:
		var threshold = float(unlock.get("threshold", 0.0))
		if threshold <= 0.0:
			continue
		if game_time >= threshold and not (threshold in flashed_time_unlock_thresholds):
			flashed_time_unlock_thresholds.append(threshold)
			if Config.unlock_pattern(unlock.get("type")):
				run_unlocked_skins["patterns"].append(unlock)
			_flash_unlock_condition_label(time_label)

func _prepare_hud_label_color(label: Label):
	if not label:
		return
	if label.label_settings:
		label.label_settings = label.label_settings.duplicate()
		label.label_settings.font_color = GameConstants.COLOR_FG
	else:
		label.add_theme_color_override("font_color", GameConstants.COLOR_FG)

func _get_hud_label_flash_color(label: Label) -> Color:
	if label == length_label:
		return GameConstants.COLOR_RANKING_LENGTH
	if label == time_label:
		return GameConstants.COLOR_RANKING_SURVIVAL
	return GameConstants.COLOR_POINT

func _flash_unlock_condition_label(label: Label):
	if not label:
		return
	_set_hud_label_color(label, _get_hud_label_flash_color(label))
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.65)
	tween.tween_method(func(color): _set_hud_label_color(label, color), _get_hud_label_flash_color(label), GameConstants.COLOR_FG, 0.35)

func _set_hud_label_color(label: Label, color: Color):
	if label.label_settings:
		label.label_settings.font_color = color
	else:
		label.add_theme_color_override("font_color", color)

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
		length_label.text = "%s: %d" % [Config.tr_text("length").to_upper(), snake.body.size()]
		_update_powerups_ui()

	time_label.text = "%s: %s" % [Config.tr_text("time").to_upper(), Config.format_survival_time(game_time)]

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
				type_name = Config.tr_text("phantom").to_upper()
				color = GameConstants.COLOR_POWERUP_GHOST # Now Purple

			GameConstants.PowerUpType.TIME_STOP:
				type_name = Config.tr_text("time_stop").to_upper()
				color = GameConstants.COLOR_POWERUP_TIME
			GameConstants.PowerUpType.DOUBLE_GROWTH:
				type_name = Config.tr_text("double_growth").to_upper()
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
var result_exit_in_progress = false
var pending_ranking_length = 0
var pending_ranking_survival = 0.0
var ranking_added = false
var ranking_add_button: Button
var result_retry_button: Button
var result_title_button: Button
var ranking_dialog_overlay: Control
var ranking_dialog_panel: PanelContainer
var ranking_name_input: LineEdit
var ranking_submit_button: Button
var ranking_dialog_back_button: Button
var ranking_feedback_label: Label
var ranking_dialog_closing = false

const RESULT_WIDTH = 660.0
const RESULT_SEPARATOR_WIDTH = 620.0
const RANKING_DIALOG_WIDTH = 540.0
const RESULT_ENTRANCE_STAGGER = 0.055
const RESULT_ENTRANCE_CONTENT_OFFSET_Y = 38.0
const RESULT_ENTRANCE_ITEM_OFFSET_Y = 26.0
const RESULT_ENTRANCE_CONTENT_FADE_TIME = 0.32
const RESULT_ENTRANCE_CONTENT_MOVE_TIME = 0.52
const RESULT_ENTRANCE_BACKDROP_FADE_TIME = 0.45
const RESULT_ENTRANCE_BLUR_TIME = 0.65
const RESULT_ENTRANCE_ITEM_FADE_TIME = 0.28
const RESULT_ENTRANCE_ITEM_MOVE_TIME = 0.38
const RESULT_ENTRANCE_ITEM_DELAY = 0.14

func show_result_screen(final_length: int, survival_time: float, longest_length: int, total_points: int):
	if is_result_showing:
		return
	is_result_showing = true
	result_exit_in_progress = false
	result_buttons.clear()
	pending_ranking_length = longest_length
	pending_ranking_survival = survival_time
	ranking_added = false
	ranking_add_button = null
	result_retry_button = null
	result_title_button = null
	ranking_dialog_overlay = null
	ranking_dialog_panel = null
	ranking_name_input = null
	ranking_submit_button = null
	ranking_dialog_back_button = null
	ranking_feedback_label = null
	ranking_dialog_closing = false

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
	blur_mat.set_shader_parameter("tint_color", Color(0.0823529, 0.0823529, 0.0823529, 0.55))
	blur_mat.set_shader_parameter("crt_enabled", Config.crt_enabled)
	blur_bg.material = blur_mat
	blur_bg.modulate.a = 0.0
	result_layer.add_child(blur_bg)
	blur_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_bg.mouse_filter = Control.MOUSE_FILTER_STOP

	var shade = ColorRect.new()
	shade.name = "ResultShade"
	shade.color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.28)
	shade.modulate.a = 0.0
	result_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Center container
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	result_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Main Content VBox
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ResultContent"
	content_vbox.custom_minimum_size = Vector2(RESULT_WIDTH, 0)
	content_vbox.add_theme_constant_override("separation", 22)
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(content_vbox)

	var anim_items: Array[Control] = []

	var visual_balance_spacer = Control.new()
	visual_balance_spacer.custom_minimum_size = Vector2(0, 32)
	content_vbox.add_child(visual_balance_spacer)

	# 1. Header
	var header_group = VBoxContainer.new()
	header_group.add_theme_constant_override("separation", 12)
	header_group.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_child(header_group)
	anim_items.append(header_group)

	var header = Label.new()
	header.text = Config.tr_text("results").to_upper()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", main_font)
	header.add_theme_font_size_override("font_size", 88)
	header.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	header_group.add_child(header)

	var subtitle = Label.new()
	subtitle.text = Config.tr_text("run_terminated").to_upper()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", main_font)
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	subtitle.modulate.a = 0.75
	header_group.add_child(subtitle)

	# Separator
	var sep_top = _create_separator()
	header_group.add_child(sep_top)

	var time_str = Config.format_survival_time(survival_time)
	var ranking_enabled = Config.can_add_ranking_entry()
	var survival_rank_text = ""
	var length_rank_text = ""
	if ranking_enabled:
		survival_rank_text = "#%d" % Config.get_survival_rank(survival_time, longest_length)
		length_rank_text = "#%d" % Config.get_length_rank(longest_length, survival_time)
	var newly_unlocked_skins = Config.unlock_skins_for_run(longest_length, survival_time)

	# 2. Primary Stats
	var hero_stats = HBoxContainer.new()
	hero_stats.add_theme_constant_override("separation", 36)
	hero_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_child(hero_stats)
	anim_items.append(hero_stats)

	var length_card = _create_result_metric(Config.tr_text("best_length").to_upper(), str(longest_length), GameConstants.COLOR_RANKING_LENGTH, 34, 58, length_rank_text)
	hero_stats.add_child(length_card)

	var time_card = _create_result_metric(Config.tr_text("survival").to_upper(), time_str, GameConstants.COLOR_RANKING_SURVIVAL, 34, 58, survival_rank_text)
	hero_stats.add_child(time_card)

	# 3. Secondary Stats
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	content_vbox.add_child(stats_vbox)
	anim_items.append(stats_vbox)

	_add_result_row(stats_vbox, Config.tr_text("final_length").to_upper(), str(final_length), 24, 34, GameConstants.COLOR_RANKING_LENGTH)
	_add_result_row(stats_vbox, Config.tr_text("points").to_upper(), str(total_points), 24, 34, GameConstants.COLOR_POINT)

	_merge_run_unlocks(newly_unlocked_skins)
	var unlock_panel = _create_result_unlock_panel(run_unlocked_skins)
	if unlock_panel:
		content_vbox.add_child(unlock_panel)
		anim_items.append(unlock_panel)

	var action_group = VBoxContainer.new()
	action_group.add_theme_constant_override("separation", 18)
	action_group.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_child(action_group)
	anim_items.append(action_group)

	var sep_bottom = _create_separator()
	action_group.add_child(sep_bottom)

	# 4. Action Buttons
	var action_vbox = VBoxContainer.new()
	action_vbox.add_theme_constant_override("separation", 10)
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_group.add_child(action_vbox)

	if Config.can_add_ranking_entry():
		ranking_add_button = _create_result_button(Config.tr_text("add_ranking").to_upper(), 34)
		ranking_add_button.pressed.connect(_on_add_ranking_pressed)
		action_vbox.add_child(ranking_add_button)
		result_buttons.append(ranking_add_button)

		ranking_dialog_overlay = _create_result_ranking_dialog()
		result_layer.add_child(ranking_dialog_overlay)

	var retry_btn = _create_result_button(Config.tr_text("retry").to_upper(), 54)
	result_retry_button = retry_btn
	retry_btn.pressed.connect(_on_retry_pressed)
	action_vbox.add_child(retry_btn)
	result_buttons.append(retry_btn)

	var title_btn = _create_result_button(Config.tr_text("main_menu").to_upper(), 36)
	result_title_button = title_btn
	title_btn.pressed.connect(_on_title_pressed)
	action_vbox.add_child(title_btn)
	result_buttons.append(title_btn)

	# Animate entrance
	_animate_result_entrance(content_vbox, blur_bg, shade, blur_mat, anim_items)

func _add_result_row(parent: Control, label_text: String, value_text: String, label_size: int, value_size: int, value_color: Color) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(RESULT_SEPARATOR_WIDTH, 0)
	hbox.add_theme_constant_override("separation", 30)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(230, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", main_font)
	label.add_theme_font_size_override("font_size", label_size)
	label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	hbox.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.custom_minimum_size = Vector2(160, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.add_theme_font_override("font", main_font)
	value.add_theme_font_size_override("font_size", value_size)
	value.add_theme_color_override("font_color", value_color)
	hbox.add_child(value)

	return hbox

func _merge_run_unlocks(newly_unlocked_skins: Dictionary):
	for unlock in newly_unlocked_skins.get("colors", []):
		if not _unlock_list_has_type(run_unlocked_skins["colors"], unlock.get("type", -1)):
			run_unlocked_skins["colors"].append(unlock)
	for unlock in newly_unlocked_skins.get("patterns", []):
		if not _unlock_list_has_type(run_unlocked_skins["patterns"], unlock.get("type", -1)):
			run_unlocked_skins["patterns"].append(unlock)

func _unlock_list_has_type(unlocks: Array, type: int) -> bool:
	for unlock in unlocks:
		if int(unlock.get("type", -1)) == type:
			return true
	return false

func _create_result_unlock_panel(newly_unlocked_skins: Dictionary) -> HBoxContainer:
	var color_unlocks = newly_unlocked_skins.get("colors", [])
	var pattern_unlocks = newly_unlocked_skins.get("patterns", [])
	if color_unlocks.is_empty() and pattern_unlocks.is_empty():
		return null

	var box = HBoxContainer.new()
	box.custom_minimum_size = Vector2(RESULT_SEPARATOR_WIDTH, 0)
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var title = Label.new()
	title.text = Config.tr_text("new_skins_unlocked").to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.add_theme_font_override("font", main_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GameConstants.COLOR_RANKING_LENGTH)
	box.add_child(title)

	var value = Label.new()
	value.text = _format_result_unlocks(color_unlocks, pattern_unlocks)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.add_theme_font_override("font", main_font)
	value.add_theme_font_size_override("font_size", 28)
	value.add_theme_color_override("font_color", GameConstants.COLOR_RANKING_LENGTH)
	box.add_child(value)

	return box

func _format_result_unlocks(color_unlocks: Array, pattern_unlocks: Array) -> String:
	var first_unlock = null
	var first_kind = ""
	if not color_unlocks.is_empty():
		first_unlock = color_unlocks[0]
		first_kind = Config.tr_text("color").to_upper()
	elif not pattern_unlocks.is_empty():
		first_unlock = pattern_unlocks[0]
		first_kind = Config.tr_text("pattern").to_upper()
	else:
		return ""

	var total_unlocks = color_unlocks.size() + pattern_unlocks.size()
	var text = "%s %s" % [first_kind, str(first_unlock.get("name", "???"))]
	if total_unlocks > 1:
		text += " +%d" % (total_unlocks - 1)
	return text

func _create_result_unlock_row(label_text: String, value_text: String, value_color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(RESULT_SEPARATOR_WIDTH, 0)
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", main_font)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	row.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.custom_minimum_size = Vector2(430, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.add_theme_font_override("font", main_font)
	value.add_theme_font_size_override("font_size", 24)
	value.add_theme_color_override("font_color", value_color)
	row.add_child(value)

	return row

func _create_result_metric(label_text: String, value_text: String, accent_color: Color, label_size: int, value_size: int, rank_text: String = "") -> VBoxContainer:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2((RESULT_SEPARATOR_WIDTH - 36) * 0.5, 0)
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label_row = HBoxContainer.new()
	label_row.alignment = BoxContainer.ALIGNMENT_CENTER
	label_row.add_theme_constant_override("separation", 12)
	box.add_child(label_row)

	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", main_font)
	label.add_theme_font_size_override("font_size", label_size)
	label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	label_row.add_child(label)

	if not rank_text.is_empty():
		var rank_label = Label.new()
		rank_label.text = rank_text
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_override("font", main_font)
		rank_label.add_theme_font_size_override("font_size", max(18, label_size - 10))
		rank_label.add_theme_color_override("font_color", accent_color)
		rank_label.modulate.a = 0.88
		label_row.add_child(rank_label)

	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_override("font", main_font)
	value.add_theme_font_size_override("font_size", value_size)
	value.add_theme_color_override("font_color", accent_color)
	box.add_child(value)

	return box

func _create_result_ranking_dialog() -> Control:
	var overlay = Control.new()
	overlay.name = "RankingDialog"
	overlay.visible = false
	overlay.modulate.a = 0.0
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scrim = ColorRect.new()
	scrim.name = "DialogScrim"
	scrim.color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.58)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center = CenterContainer.new()
	center.name = "DialogCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	ranking_dialog_panel = PanelContainer.new()
	ranking_dialog_panel.name = "DialogPanel"
	ranking_dialog_panel.custom_minimum_size = Vector2(RANKING_DIALOG_WIDTH, 0)
	ranking_dialog_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ranking_dialog_panel.add_theme_stylebox_override("panel", _create_dialog_panel_style())
	center.add_child(ranking_dialog_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	ranking_dialog_panel.add_child(margin)

	var form = VBoxContainer.new()
	form.name = "RankingForm"
	form.add_theme_constant_override("separation", 10)
	form.alignment = BoxContainer.ALIGNMENT_CENTER
	form.process_mode = Node.PROCESS_MODE_ALWAYS
	margin.add_child(form)

	var title = Label.new()
	title.text = Config.tr_text("add_ranking").to_upper()
	title.custom_minimum_size = Vector2(RANKING_DIALOG_WIDTH - 100, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", main_font)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	form.add_child(title)

	var stats = VBoxContainer.new()
	stats.custom_minimum_size = Vector2(RANKING_DIALOG_WIDTH - 100, 0)
	stats.add_theme_constant_override("separation", 6)
	form.add_child(stats)
	_add_dialog_stat_row(
		stats,
		Config.tr_text("best_length").to_upper(),
		str(pending_ranking_length),
		"#%d" % Config.get_length_rank(pending_ranking_length, pending_ranking_survival),
		GameConstants.COLOR_RANKING_LENGTH
	)
	_add_dialog_stat_row(
		stats,
		Config.tr_text("survival").to_upper(),
		Config.format_survival_time(pending_ranking_survival),
		"#%d" % Config.get_survival_rank(pending_ranking_survival, pending_ranking_length),
		GameConstants.COLOR_RANKING_SURVIVAL
	)

	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 14)
	input_row.alignment = BoxContainer.ALIGNMENT_CENTER
	form.add_child(input_row)

	ranking_name_input = LineEdit.new()
	ranking_name_input.placeholder_text = Config.tr_text("name").to_upper()
	ranking_name_input.max_length = Config.PLAYER_NAME_MAX_LENGTH
	ranking_name_input.custom_minimum_size = Vector2(260, 54)
	ranking_name_input.process_mode = Node.PROCESS_MODE_ALWAYS
	_style_result_line_edit(ranking_name_input)
	ranking_name_input.text_submitted.connect(func(_submitted_text): _on_submit_ranking_pressed())
	ranking_name_input.text_changed.connect(func(_new_text): _on_ranking_name_changed())
	input_row.add_child(ranking_name_input)

	ranking_submit_button = _create_result_button(Config.tr_text("submit").to_upper(), 32)
	ranking_submit_button.disabled = true  # 初期状態は無効（名前未入力のため）
	ranking_submit_button.pressed.connect(_on_submit_ranking_pressed)
	input_row.add_child(ranking_submit_button)
	result_buttons.append(ranking_submit_button)

	ranking_feedback_label = Label.new()
	ranking_feedback_label.text = Config.tr_text("name_error_empty")
	ranking_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ranking_feedback_label.add_theme_font_override("font", main_font)
	ranking_feedback_label.add_theme_font_size_override("font_size", 22)
	ranking_feedback_label.add_theme_color_override("font_color", GameConstants.COLOR_SNAKE)
	ranking_feedback_label.visible = true  # 初期状態でエラーを表示
	form.add_child(ranking_feedback_label)

	ranking_dialog_back_button = _create_result_button(Config.tr_text("back").to_upper(), 28)
	ranking_dialog_back_button.pressed.connect(_close_ranking_dialog)
	form.add_child(ranking_dialog_back_button)
	result_buttons.append(ranking_dialog_back_button)

	return overlay

func _add_dialog_stat_row(parent: Control, label_text: String, value_text: String, rank_text: String, value_color: Color):
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(RANKING_DIALOG_WIDTH - 100, 0)
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	parent.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_override("font", main_font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	row.add_child(label)

	var value = Label.new()
	value.text = value_text
	value.custom_minimum_size = Vector2(146, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.add_theme_font_override("font", main_font)
	value.add_theme_font_size_override("font_size", 30)
	value.add_theme_color_override("font_color", value_color)
	row.add_child(value)

	var rank = Label.new()
	rank.text = rank_text
	rank.custom_minimum_size = Vector2(74, 0)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank.add_theme_font_override("font", main_font)
	rank.add_theme_font_size_override("font_size", 26)
	rank.add_theme_color_override("font_color", value_color)
	row.add_child(rank)

func _create_dialog_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.96)
	style.border_color = GameConstants.COLOR_GHOST
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	return style

func _style_result_line_edit(input: LineEdit):
	input.add_theme_font_override("font", main_font)
	input.add_theme_font_size_override("font_size", 28)
	input.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	input.add_theme_color_override("font_placeholder_color", GameConstants.COLOR_GHOST)
	input.add_theme_color_override("caret_color", GameConstants.COLOR_POINT)
	input.add_theme_color_override("selection_color", GameConstants.COLOR_ACCENT_BLUE.darkened(0.45))

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(GameConstants.COLOR_BLOCK_BORDER.r, GameConstants.COLOR_BLOCK_BORDER.g, GameConstants.COLOR_BLOCK_BORDER.b, 0.92)
	normal.border_color = GameConstants.COLOR_GHOST
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(0)
	normal.set_content_margin(SIDE_LEFT, 12)
	normal.set_content_margin(SIDE_RIGHT, 12)
	normal.set_content_margin(SIDE_TOP, 6)
	normal.set_content_margin(SIDE_BOTTOM, 6)
	input.add_theme_stylebox_override("normal", normal)

	var focus = normal.duplicate() as StyleBoxFlat
	focus.border_color = GameConstants.COLOR_POINT
	input.add_theme_stylebox_override("focus", focus)

	var read_only = normal.duplicate() as StyleBoxFlat
	read_only.border_color = GameConstants.COLOR_SNAKE
	input.add_theme_stylebox_override("read_only", read_only)

func _on_add_ranking_pressed():
	if ranking_added or not ranking_dialog_overlay or not Config.can_add_ranking_entry():
		return
	await _open_ranking_dialog()

func _is_ranking_dialog_open() -> bool:
	if not ranking_dialog_overlay or not is_instance_valid(ranking_dialog_overlay):
		return false
	return ranking_dialog_overlay.visible and not ranking_dialog_closing

func _open_ranking_dialog():
	if not ranking_dialog_overlay:
		return
	if ranking_dialog_overlay.visible:
		return
	ranking_dialog_closing = false
	ranking_dialog_overlay.visible = true
	ranking_dialog_overlay.modulate.a = 0.0
	await get_tree().process_frame

	if ranking_dialog_panel:
		ranking_dialog_panel.scale = Vector2(0.94, 0.94)
		ranking_dialog_panel.pivot_offset = ranking_dialog_panel.size / 2

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(ranking_dialog_overlay, "modulate:a", 1.0, 0.18)
	if ranking_dialog_panel:
		tween.tween_property(ranking_dialog_panel, "scale", Vector2.ONE, 0.24)

	if ranking_name_input:
		ranking_name_input.grab_focus()

func _close_ranking_dialog():
	if not ranking_dialog_overlay or not ranking_dialog_overlay.visible:
		return
	if ranking_dialog_closing:
		return
	ranking_dialog_closing = true
	if ranking_name_input:
		ranking_name_input.release_focus()
	if ranking_submit_button:
		ranking_submit_button.release_focus()
	if ranking_dialog_back_button:
		ranking_dialog_back_button.release_focus()

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(ranking_dialog_overlay, "modulate:a", 0.0, 0.14)
	if ranking_dialog_panel:
		ranking_dialog_panel.pivot_offset = ranking_dialog_panel.size / 2
		tween.tween_property(ranking_dialog_panel, "scale", Vector2(0.96, 0.96), 0.14)
	await tween.finished

	if ranking_dialog_overlay and is_instance_valid(ranking_dialog_overlay):
		ranking_dialog_overlay.visible = false
	ranking_dialog_closing = false
	if ranking_add_button and not ranking_added:
		ranking_add_button.grab_focus()

func _on_ranking_name_changed():
	if not ranking_name_input or not ranking_submit_button or not ranking_feedback_label:
		return
	var error_key = Config.validate_player_name(ranking_name_input.text)
	var is_valid = error_key.is_empty()
	ranking_submit_button.disabled = not is_valid
	if is_valid:
		ranking_feedback_label.visible = false
		ranking_feedback_label.text = ""
		# 入力ボーダーをフォーカスカラーに戻す
		_set_name_input_border_valid(true)
	else:
		ranking_feedback_label.visible = true
		ranking_feedback_label.text = Config.tr_text(error_key)
		_set_name_input_border_valid(false)

func _set_name_input_border_valid(valid: bool):
	if not ranking_name_input:
		return
	var normal = ranking_name_input.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if not normal:
		return
	normal.border_color = GameConstants.COLOR_POINT if valid else GameConstants.COLOR_SNAKE
	ranking_name_input.add_theme_stylebox_override("normal", normal)

func _on_submit_ranking_pressed():
	if ranking_added or not ranking_name_input or not Config.can_add_ranking_entry():
		return
	# 送信前に再バリデーション
	var error_key = Config.validate_player_name(ranking_name_input.text)
	if not error_key.is_empty():
		if ranking_feedback_label:
			ranking_feedback_label.visible = true
			ranking_feedback_label.text = Config.tr_text(error_key)
		return
	var entry = Config.add_ranking_entry(ranking_name_input.text, pending_ranking_length, pending_ranking_survival)
	if entry.is_empty():
		return
	ranking_added = true
	ranking_name_input.text = entry.get("name", "PLAYER")
	ranking_name_input.editable = false
	if ranking_submit_button:
		ranking_submit_button.disabled = true
	if ranking_add_button:
		ranking_add_button.text = Config.tr_text("saved").to_upper()
		ranking_add_button.disabled = true
	if ranking_feedback_label:
		ranking_feedback_label.visible = true
		ranking_feedback_label.text = Config.tr_text("saved").to_upper()

func _create_separator() -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(RESULT_SEPARATOR_WIDTH, 2)
	sep.color = GameConstants.COLOR_GHOST
	sep.color.a = 0.25
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return sep

func _create_result_button(text: String, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(_get_result_button_min_width(text), btn.custom_minimum_size.y)
	btn.add_theme_font_override("font", main_font)
	btn.add_theme_font_size_override("font_size", font_size)
	_apply_result_button_colors(btn)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.focus_mode = Control.FOCUS_ALL

	btn.mouse_entered.connect(func(): _animate_result_btn(btn, true))
	btn.mouse_exited.connect(func(): _animate_result_btn(btn, false))
	btn.button_down.connect(func(): _on_result_btn_down(btn))
	btn.button_up.connect(func(): _on_result_btn_up(btn))

	return btn

func _get_result_button_min_width(text: String) -> float:
	match text:
		"SUBMIT":
			return 190.0
		"RETRY":
			return 260.0
	if text == Config.tr_text("submit").to_upper():
		return 190.0
	if text == Config.tr_text("retry").to_upper():
		return 260.0
	if text == Config.tr_text("add_ranking").to_upper():
		return 380.0
	return 320.0

func _apply_result_button_colors(btn: Button):
	var accent_color = _get_result_button_accent_color()
	btn.add_theme_color_override("font_color", GameConstants.COLOR_BUTTON_NORMAL)
	btn.add_theme_color_override("font_hover_color", accent_color)
	btn.add_theme_color_override("font_pressed_color", accent_color.darkened(GameConstants.BUTTON_PRESSED_DARKEN))
	btn.add_theme_color_override("font_focus_color", GameConstants.COLOR_BUTTON_NORMAL)
	btn.add_theme_color_override("font_disabled_color", GameConstants.COLOR_GHOST)

func _get_result_button_accent_color() -> Color:
	return GameConstants.SKIN_COLORS.get(Config.selected_color, GameConstants.COLOR_BUTTON_HOVER)

func _animate_result_btn(btn: Button, hover: bool):
	if result_exit_in_progress:
		return
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hover:
		tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.2)
	else:
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)

func _on_result_btn_down(btn: Button):
	if result_exit_in_progress:
		return
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.05)
	tween.tween_property(btn, "self_modulate", Color(0.8, 0.8, 0.8), 0.05)

func _on_result_btn_up(btn: Button):
	if result_exit_in_progress:
		return
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.08, 1.08) if btn.is_hovered() else Vector2(1.0, 1.0)
	tween.tween_property(btn, "scale", target_scale, 0.1)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.1)

func _animate_result_entrance(container: Control, blur_bg: ColorRect, shade: ColorRect, blur_mat: ShaderMaterial, anim_items: Array[Control]):
	container.modulate.a = 0
	container.scale = Vector2(0.96, 0.96)

	# Keep the shader color stable during fade-in; animate only opacity/blur strength.
	blur_bg.modulate.a = 0.0
	shade.modulate.a = 0.0
	blur_mat.set_shader_parameter("blur_amount", 2.0)

	for i in range(anim_items.size()):
		var item = anim_items[i]
		item.modulate.a = 0.0
		item.position.y += RESULT_ENTRANCE_ITEM_OFFSET_Y

	# Wait one frame to let the container finish layout and find the centered Y
	await get_tree().process_frame

	var target_y = container.position.y
	container.position.y += RESULT_ENTRANCE_CONTENT_OFFSET_Y
	container.pivot_offset = container.size / 2

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	# UI Animation
	tween.tween_property(container, "modulate:a", 1.0, RESULT_ENTRANCE_CONTENT_FADE_TIME)
	tween.tween_property(container, "position:y", target_y, RESULT_ENTRANCE_CONTENT_MOVE_TIME)
	tween.tween_property(container, "scale", Vector2.ONE, RESULT_ENTRANCE_CONTENT_MOVE_TIME)

	# Blur Animation
	tween.tween_property(blur_bg, "modulate:a", 1.0, RESULT_ENTRANCE_BACKDROP_FADE_TIME)
	tween.tween_property(shade, "modulate:a", 1.0, RESULT_ENTRANCE_BACKDROP_FADE_TIME)
	tween.tween_property(blur_mat, "shader_parameter/blur_amount", 5.0, RESULT_ENTRANCE_BLUR_TIME)

	for i in range(anim_items.size()):
		var item = anim_items[i]
		var target_item_y = item.position.y - RESULT_ENTRANCE_ITEM_OFFSET_Y
		var delay = RESULT_ENTRANCE_ITEM_DELAY + i * RESULT_ENTRANCE_STAGGER
		tween.tween_property(item, "modulate:a", 1.0, RESULT_ENTRANCE_ITEM_FADE_TIME).set_delay(delay)
		tween.tween_property(item, "position:y", target_item_y, RESULT_ENTRANCE_ITEM_MOVE_TIME).set_delay(delay)


func _update_result_button_pivots():
	for btn in result_buttons:
		if is_instance_valid(btn):
			btn.pivot_offset = btn.size / 2

	# Also update main content vbox pivot for scale animation
	if not result_layer:
		return
	var center = result_layer.get_node_or_null("CenterContainer")
	if center:
		var vbox = center.get_child(0) if center.get_child_count() > 0 else null
		if vbox:
			vbox.pivot_offset = vbox.size / 2

func _on_retry_pressed():
	if result_exit_in_progress:
		return
	if not Config.consume_retry_action():
		return
	await _animate_result_exit()
	get_tree().paused = false
	is_result_showing = false
	result_buttons.clear()
	get_tree().reload_current_scene()

func _on_title_pressed():
	if result_exit_in_progress:
		return
	await _animate_result_exit()
	get_tree().paused = false
	is_result_showing = false
	result_buttons.clear()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _animate_result_exit():
	result_exit_in_progress = true
	for btn in result_buttons:
		if is_instance_valid(btn):
			btn.disabled = true

	if not result_layer:
		return

	var center = result_layer.get_node_or_null("CenterContainer")
	var content = center.get_child(0) if center and center.get_child_count() > 0 else null
	var blur_bg = result_layer.get_node_or_null("BlurBG") as ColorRect
	var shade = result_layer.get_node_or_null("ResultShade") as ColorRect
	var blur_mat = blur_bg.material as ShaderMaterial if blur_bg and blur_bg.material else null

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	if content:
		content.pivot_offset = content.size / 2
		tween.tween_property(content, "modulate:a", 0.0, 0.18)
		tween.tween_property(content, "scale", Vector2(0.96, 0.96), 0.18)
		tween.tween_property(content, "position:y", content.position.y - 22.0, 0.18)

	if blur_bg:
		var blur_fade_out = tween.tween_property(blur_bg, "modulate:a", 0.0, 0.28)
		if blur_fade_out:
			blur_fade_out.set_delay(0.08)

	if shade:
		var shade_fade_out = tween.tween_property(shade, "modulate:a", 0.0, 0.28)
		if shade_fade_out:
			shade_fade_out.set_delay(0.08)

	if blur_mat:
		var blur_out = tween.tween_property(blur_mat, "shader_parameter/blur_amount", 0.0, 0.28)
		if blur_out:
			blur_out.set_delay(0.02)

	await tween.finished

	if result_layer and is_instance_valid(result_layer):
		result_layer.queue_free()
	result_layer = null
