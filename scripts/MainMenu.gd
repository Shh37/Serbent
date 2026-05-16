extends Control

var font_title: Font
var font_text: Font

var title_pos = Vector2.ZERO
var skin_buttons = []
var ranking_sort_key = "length"
var ranking_rows_container: VBoxContainer
var ranking_empty_label: Label
var ranking_length_sort_btn: Button
var ranking_survival_sort_btn: Button
var ranking_back_btn: Button
var ranking_scroll: ScrollContainer
var ranking_scroll_velocity: float = 0.0

func _ready():
	font_title = load("res://assets/Shikakufuto_Free.ttf")
	font_text = load("res://assets/BestTen-CRT.otf")

	# Set theme fonts
	var title = $CenterContainer/VBoxContainer/TitleContainer/Title
	title.add_theme_font_override("normal_font", font_title)
	title_pos = title.position

	var play_btn = $CenterContainer/VBoxContainer/ButtonContainer/PlayButton
	play_btn.add_theme_font_override("font", font_title)

	var button_container = $CenterContainer/VBoxContainer/ButtonContainer
	var ranking_btn = _ensure_ranking_button(button_container)
	ranking_btn.add_theme_font_override("font", font_title)

	var settings_btn = $CenterContainer/VBoxContainer/ButtonContainer/SettingsButton
	settings_btn.add_theme_font_override("font", font_title)

	var skins_btn = $CenterContainer/VBoxContainer/ButtonContainer/SkinsButton
	skins_btn.add_theme_font_override("font", font_title)

	_ensure_ranking_layer()

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

	var color_label = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/ColorLabel
	color_label.add_theme_font_override("font", font_title)
	color_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var pattern_label = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/PatternLabel
	pattern_label.add_theme_font_override("font", font_title)
	pattern_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	_populate_skin_grids()

	# Set colors using GameConstants (class_name)
	title.add_theme_color_override("default_color", GameConstants.COLOR_FG)

	play_btn.pressed.connect(_on_play_pressed)
	ranking_btn.pressed.connect(_on_ranking_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	skins_btn.pressed.connect(_on_skins_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	skin_back_btn.pressed.connect(_on_skin_back_pressed)
	ranking_back_btn.pressed.connect(_on_ranking_back_pressed)
	ranking_length_sort_btn.pressed.connect(func(): _on_ranking_sort_pressed("length"))
	ranking_survival_sort_btn.pressed.connect(func(): _on_ranking_sort_pressed("survival"))

	for btn in [play_btn, ranking_btn, settings_btn, skins_btn, back_btn, skin_back_btn, ranking_back_btn, ranking_length_sort_btn, ranking_survival_sort_btn, crt_on_btn, crt_off_btn, beta_on_btn, beta_off_btn]:
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

	# Signals for dynamically created skin buttons are connected in _populate_skin_grids

	# Sync initial appearance
	_update_appearance_display()
	_refresh_ranking_display()
	Config.rankings_changed.connect(_refresh_ranking_display)

	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	_update_crt_buttons_style(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)
	Config.crt_changed.connect(_update_crt_buttons_style)

	_update_beta_buttons_style(Config.beta_upgrades_enabled)
	Config.beta_upgrades_changed.connect(_update_beta_buttons_style)

	# Initial style
	for btn in [play_btn, ranking_btn, settings_btn, back_btn, ranking_back_btn, ranking_length_sort_btn, ranking_survival_sort_btn, crt_on_btn, crt_off_btn, beta_on_btn, beta_off_btn]:
		btn.pivot_offset = btn.size / 2

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed():
	$SettingsLayer.visible = true

func _on_skins_pressed():
	$SkinLayer.visible = true

func _on_ranking_pressed():
	_refresh_ranking_display()
	$RankingLayer.visible = true

func _on_back_pressed():
	$SettingsLayer.visible = false

func _on_skin_back_pressed():
	$SkinLayer.visible = false

func _on_ranking_back_pressed():
	$RankingLayer.visible = false

func _on_ranking_sort_pressed(sort_key: String):
	ranking_sort_key = sort_key
	_refresh_ranking_display()

func _on_crt_toggle_pressed(enabled: bool):
	Config.crt_enabled = enabled

func _on_beta_toggle_pressed(enabled: bool):
	Config.beta_upgrades_enabled = enabled

func _on_ranking_scroll_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			ranking_scroll_velocity = 0
		
		var impulse = 1200.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			ranking_scroll_velocity -= impulse
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			ranking_scroll_velocity += impulse
			accept_event()


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

func _ensure_ranking_button(button_container: VBoxContainer) -> Button:
	var existing = button_container.get_node_or_null("RankingButton") as Button
	if existing:
		return existing

	var btn = Button.new()
	btn.name = "RankingButton"
	btn.text = "RANKING"
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 50)
	button_container.add_child(btn)
	button_container.move_child(btn, 2)
	return btn

func _ensure_ranking_layer():
	var existing = get_node_or_null("RankingLayer") as CanvasLayer
	if existing:
		ranking_length_sort_btn = existing.get_node("CenterContainer/VBoxContainer/SortButtons/LengthSortButton") as Button
		ranking_survival_sort_btn = existing.get_node("CenterContainer/VBoxContainer/SortButtons/SurvivalSortButton") as Button
		ranking_rows_container = existing.get_node("CenterContainer/VBoxContainer/Table/ScrollContainer/MarginContainer/Rows") as VBoxContainer
		ranking_scroll = existing.get_node("CenterContainer/VBoxContainer/Table/ScrollContainer") as ScrollContainer
		ranking_empty_label = existing.get_node("CenterContainer/VBoxContainer/Table/EmptyLabel") as Label
		ranking_back_btn = existing.get_node("CenterContainer/VBoxContainer/BackButton") as Button
		return

	var layer = CanvasLayer.new()
	layer.name = "RankingLayer"
	layer.layer = 2
	layer.visible = false
	add_child(layer)

	var blur_bg = ColorRect.new()
	blur_bg.name = "ColorRect"
	var blur_shader = load("res://shaders/ui_blur.gdshader")
	var blur_mat = ShaderMaterial.new()
	blur_mat.shader = blur_shader
	blur_mat.set_shader_parameter("blur_amount", 5.0)
	blur_mat.set_shader_parameter("tint_color", Color(0.0823529, 0.0823529, 0.0823529, 0.6))
	blur_mat.set_shader_parameter("crt_enabled", Config.crt_enabled)
	blur_bg.material = blur_mat
	layer.add_child(blur_bg)
	blur_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_bg.mouse_filter = Control.MOUSE_FILTER_STOP

	var center = CenterContainer.new()
	center.name = "CenterContainer"
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.custom_minimum_size = Vector2(1000, 0)
	vbox.add_theme_constant_override("separation", 22)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title = Label.new()
	title.name = "Label"
	title.text = "RANKING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_title)
	title.add_theme_font_size_override("font_size", 78)
	title.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	vbox.add_child(title)

	var sort_buttons = HBoxContainer.new()
	sort_buttons.name = "SortButtons"
	sort_buttons.add_theme_constant_override("separation", 34)
	sort_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(sort_buttons)

	ranking_length_sort_btn = _create_ranking_button("BEST LENGTH", 32, 280)
	ranking_length_sort_btn.name = "LengthSortButton"
	sort_buttons.add_child(ranking_length_sort_btn)

	ranking_survival_sort_btn = _create_ranking_button("SURVIVAL", 32, 240)
	ranking_survival_sort_btn.name = "SurvivalSortButton"
	sort_buttons.add_child(ranking_survival_sort_btn)

	var table = VBoxContainer.new()
	table.name = "Table"
	table.custom_minimum_size = Vector2(1000, 0)
	table.add_theme_constant_override("separation", 8)
	vbox.add_child(table)

	var header_margin = MarginContainer.new()
	header_margin.name = "HeaderMargin"
	header_margin.add_theme_constant_override("margin_right", 52) # 40 (row margin) + 12 (scrollbar)
	table.add_child(header_margin)

	var header = HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 22)
	header_margin.add_child(header)
	header.add_child(_create_ranking_cell("#", 80, HORIZONTAL_ALIGNMENT_CENTER, 24, GameConstants.COLOR_GHOST))
	header.add_child(_create_ranking_cell("NAME", 250, HORIZONTAL_ALIGNMENT_LEFT, 24, GameConstants.COLOR_GHOST, true))
	header.add_child(_create_ranking_cell("BEST LENGTH", 200, HORIZONTAL_ALIGNMENT_RIGHT, 24, GameConstants.COLOR_GHOST))
	header.add_child(_create_ranking_cell("SURVIVAL", 200, HORIZONTAL_ALIGNMENT_RIGHT, 24, GameConstants.COLOR_GHOST))

	ranking_scroll = ScrollContainer.new()
	ranking_scroll.name = "ScrollContainer"
	ranking_scroll.custom_minimum_size = Vector2(1000, 400)
	ranking_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ranking_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	# Custom Scrollbar Styling
	var scrollbar = ranking_scroll.get_v_scroll_bar()
	var grabber_sb = StyleBoxFlat.new()
	grabber_sb.bg_color = GameConstants.COLOR_FG
	grabber_sb.set_corner_radius_all(0) # Boxy/Square
	grabber_sb.expand_margin_left = 2
	grabber_sb.expand_margin_right = 2
	
	var track_sb = StyleBoxFlat.new()
	track_sb.bg_color = GameConstants.COLOR_BLOCK_BORDER
	track_sb.set_corner_radius_all(0) # Boxy/Square
	track_sb.expand_margin_left = 2
	track_sb.expand_margin_right = 2
	
	scrollbar.add_theme_stylebox_override("grabber", grabber_sb)
	scrollbar.add_theme_stylebox_override("grabber_highlight", grabber_sb)
	scrollbar.add_theme_stylebox_override("grabber_pressed", grabber_sb)
	scrollbar.add_theme_stylebox_override("scroll", track_sb)
	scrollbar.custom_minimum_size.x = 12 # Thinner track
	
	ranking_scroll.gui_input.connect(_on_ranking_scroll_input)
	
	table.add_child(ranking_scroll)

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_right", 40) # Space between rows and scrollbar
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ranking_scroll.add_child(margin)

	ranking_rows_container = VBoxContainer.new()
	ranking_rows_container.name = "Rows"
	ranking_rows_container.add_theme_constant_override("separation", 4)
	ranking_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(ranking_rows_container)

	ranking_empty_label = Label.new()
	ranking_empty_label.name = "EmptyLabel"
	ranking_empty_label.text = "NO RANKINGS YET"
	ranking_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ranking_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ranking_empty_label.custom_minimum_size = Vector2(0, 400)
	ranking_empty_label.add_theme_font_override("font", font_title)
	ranking_empty_label.add_theme_font_size_override("font_size", 30)
	ranking_empty_label.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)
	table.add_child(ranking_empty_label)

	ranking_back_btn = _create_ranking_button("BACK", 40, 180)
	ranking_back_btn.name = "BackButton"
	vbox.add_child(ranking_back_btn)

func _create_ranking_button(text: String, font_size: int, min_width: float) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.flat = true
	btn.custom_minimum_size = Vector2(min_width, 0)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", font_title)
	btn.add_theme_font_size_override("font_size", font_size)
	return btn

func _create_ranking_cell(text: String, min_width: float, alignment: int, font_size: int, color: Color, expand: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0)
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", font_title)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _refresh_ranking_display():
	if not ranking_rows_container:
		return
	for child in ranking_rows_container.get_children():
		child.free()

	_update_ranking_sort_buttons_style()
	var entries = Config.get_rankings(ranking_sort_key)
	ranking_empty_label.visible = entries.is_empty()
	if ranking_scroll:
		ranking_scroll.visible = not entries.is_empty()

	var last_score: float = -1.0
	var current_display_rank: int = 0

	for i in range(entries.size()):
		var entry = entries[i]
		var current_score: float = float(entry.get("best_length", 0)) if ranking_sort_key == "length" else float(entry.get("survival_time", 0.0))

		if i == 0 or not is_equal_approx(current_score, last_score):
			current_display_rank = i + 1
		last_score = current_score

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		row.custom_minimum_size = Vector2(840, 36)
		ranking_rows_container.add_child(row)

		var rank_color = GameConstants.COLOR_POINT if current_display_rank <= 3 else GameConstants.COLOR_FG
		var value_color = GameConstants.COLOR_FG
		row.add_child(_create_ranking_cell(str(current_display_rank), 80, HORIZONTAL_ALIGNMENT_CENTER, 28, rank_color))
		row.add_child(_create_ranking_cell(str(entry.get("name", "PLAYER")), 250, HORIZONTAL_ALIGNMENT_LEFT, 28, value_color, true))
		row.add_child(_create_ranking_cell(str(int(entry.get("best_length", 0))), 200, HORIZONTAL_ALIGNMENT_RIGHT, 28, GameConstants.COLOR_ACCENT_BLUE))
		row.add_child(_create_ranking_cell(Config.format_survival_time(float(entry.get("survival_time", 0.0))), 200, HORIZONTAL_ALIGNMENT_RIGHT, 28, GameConstants.COLOR_POINT))

func _update_ranking_sort_buttons_style():
	if not ranking_length_sort_btn or not ranking_survival_sort_btn:
		return
	var length_active = ranking_sort_key == "length"
	ranking_length_sort_btn.add_theme_color_override("font_color", GameConstants.COLOR_ACCENT_BLUE if length_active else GameConstants.COLOR_GHOST)
	ranking_survival_sort_btn.add_theme_color_override("font_color", GameConstants.COLOR_POINT if not length_active else GameConstants.COLOR_GHOST)

func _populate_skin_grids():
	var color_grid = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/ColorGrid
	var pattern_grid = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/PatternGrid

	var color_names = {
		GameConstants.SkinColor.BASIC: "BASIC",
		GameConstants.SkinColor.MINT: "MINT",
		GameConstants.SkinColor.OLIVE: "OLIVE",
		GameConstants.SkinColor.MOSS: "MOSS",
		GameConstants.SkinColor.LIME: "LIME",
		GameConstants.SkinColor.EMERALD: "EMERALD"
	}
	for c_type in GameConstants.SkinColor.values():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(210, 45)
		btn.flat = true
		btn.pressed.connect(func(): _on_color_selected(c_type))

		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rtl.add_theme_font_override("normal_font", font_title)
		rtl.add_theme_font_size_override("normal_font_size", 26)
		rtl.fit_content = true
		rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		center.add_child(rtl)
		btn.add_child(center)

		_setup_skin_button(btn)
		color_grid.add_child(btn)
		btn.set_meta("color_type", c_type)
		btn.set_meta("base_text", color_names.get(c_type, "???"))

	var pattern_names = {
		GameConstants.SkinPattern.SOLID: "SOLID",
		GameConstants.SkinPattern.STRIPE11: "ST1-1",
		GameConstants.SkinPattern.STRIPE12: "ST1-2",
		GameConstants.SkinPattern.STRIPE21: "ST2-1",
		GameConstants.SkinPattern.STRIPE22: "ST2-2",
		GameConstants.SkinPattern.GRADIENT: "GRAD"
	}
	for p_type in GameConstants.SkinPattern.values():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(210, 45)
		btn.flat = true
		btn.pressed.connect(func(): _on_pattern_selected(p_type))

		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rtl.add_theme_font_override("normal_font", font_title)
		rtl.add_theme_font_size_override("normal_font_size", 26)
		rtl.fit_content = true
		rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		center.add_child(rtl)
		btn.add_child(center)

		_setup_skin_button(btn)
		pattern_grid.add_child(btn)
		btn.set_meta("pattern_type", p_type)
		btn.set_meta("base_text", pattern_names.get(p_type, "???"))

func _setup_skin_button(btn: Button):
	btn.mouse_entered.connect(func(): _update_button_style(btn, true))
	btn.mouse_exited.connect(func(): _update_button_style(btn, false))
	btn.button_down.connect(func(): _on_button_down(btn))
	btn.button_up.connect(func(): _on_button_up(btn))
	skin_buttons.append(btn)

func _on_color_selected(c_type):
	if c_type in Config.unlocked_colors:
		Config.selected_color = c_type
		_update_appearance_display()

func _on_pattern_selected(p_type):
	if p_type in Config.unlocked_patterns:
		Config.selected_pattern = p_type
		_update_appearance_display()

func get_pattern_bbcode(text: String, pattern: GameConstants.SkinPattern, base_color: Color, prefix_color: String) -> String:
	var darker_color = base_color.darkened(0.3)
	var bbcode = ""

	bbcode += "[color=#" + prefix_color + "]> [/color]"

	for i in range(text.length()):
		var char_color = base_color
		match pattern:
			GameConstants.SkinPattern.STRIPE11:
				char_color = base_color if i % 2 == 0 else darker_color
			GameConstants.SkinPattern.STRIPE12:
				char_color = base_color if i % 3 == 0 else darker_color
			GameConstants.SkinPattern.STRIPE21:
				char_color = base_color if i % 3 != 2 else darker_color
			GameConstants.SkinPattern.STRIPE22:
				char_color = base_color if (i / 2) % 2 == 0 else darker_color
			GameConstants.SkinPattern.GRADIENT:
				var t = float(i) / float(max(1, text.length() - 1))
				char_color = base_color.lerp(darker_color, t)

		if i == 0:
			char_color = char_color.lightened(0.2)

		bbcode += "[color=#" + char_color.to_html(false) + "]" + text[i] + "[/color]"

	bbcode += "[color=#" + prefix_color + "] <[/color]"
	return bbcode

func _update_appearance_display():
	var c_type = Config.selected_color
	var p_type = Config.selected_pattern

	var base_color = GameConstants.SKIN_COLORS[c_type]

	var color_grid = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/ColorGrid
	if color_grid:
		for btn in color_grid.get_children():
			var btn_c = btn.get_meta("color_type")
			var rtl = btn.get_child(0).get_child(0)
			var text_str = btn.get_meta("base_text")

			var is_selected = (btn_c == c_type)
			var is_unlocked = (btn_c in Config.unlocked_colors)

			var disp_text = text_str
			var prefix_color = base_color.to_html(false) if is_selected else "00000000"

			var color_to_use = GameConstants.SKIN_COLORS[btn_c] if is_unlocked else GameConstants.COLOR_BG.lightened(0.1)
			var hover_color = color_to_use.lightened(0.2)

			if btn.is_hovered():
				color_to_use = hover_color

			rtl.text = "[color=#" + prefix_color + "]> [/color][color=#" + color_to_use.to_html(false) + "]" + disp_text + "[/color][color=#" + prefix_color + "] <[/color]"

	var pattern_grid = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/PatternGrid
	if pattern_grid:
		for btn in pattern_grid.get_children():
			var btn_p = btn.get_meta("pattern_type")
			var rtl = btn.get_child(0).get_child(0)
			var text_str = btn.get_meta("base_text")

			var is_selected = (btn_p == p_type)
			var is_unlocked = (btn_p in Config.unlocked_patterns)

			var disp_text = text_str
			var prefix_color = base_color.to_html(false) if is_selected else "00000000"

			if not is_unlocked:
				rtl.text = "[color=#" + prefix_color + "]> [/color][color=#" + GameConstants.COLOR_BG.lightened(0.1).to_html(false) + "]" + disp_text + "[/color][color=#" + prefix_color + "] <[/color]"
			else:
				var active_color = base_color
				if btn.is_hovered():
					active_color = active_color.lightened(0.2)
				rtl.text = get_pattern_bbcode(disp_text, btn_p, active_color, prefix_color)

	# Update Preview
	var preview = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/PreviewContainer/SnakePreview
	if preview:
		preview.color_type = c_type
		preview.pattern_type = p_type

	# Update menu buttons hover color to match selected color
	var standard_btns = [
		$CenterContainer/VBoxContainer/ButtonContainer/PlayButton,
		$CenterContainer/VBoxContainer/ButtonContainer/RankingButton,
		$CenterContainer/VBoxContainer/ButtonContainer/SkinsButton,
		$CenterContainer/VBoxContainer/ButtonContainer/SettingsButton,
		$SettingsLayer/CenterContainer/VBoxContainer/BackButton,
		$SkinLayer/CenterContainer/VBoxContainer/BackButton,
		ranking_back_btn,
		ranking_length_sort_btn,
		ranking_survival_sort_btn
	]
	for btn in standard_btns:
		if btn:
			btn.add_theme_color_override("font_hover_color", base_color)

	# Visual feedback on background
	var bg = $MenuBackground
	if bg.has_method("set_snake_color"):
		bg.set_snake_color(base_color)

	# Update Title "B" color
	var title = $CenterContainer/VBoxContainer/TitleContainer/Title
	if title:
		var yellow_color = GameConstants.COLOR_POINT.to_html(false)
		var b_color = base_color.to_html(false)
		title.text = "[center][color=#" + yellow_color + "]SER[/color][color=#" + b_color + "]B[/color][color=#" + yellow_color + "]ENT[/color][/center]"

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

	var ranking_blur = $RankingLayer/ColorRect
	if ranking_blur and ranking_blur.material:
		ranking_blur.material.set_shader_parameter("crt_enabled", enabled)

func _update_button_style(btn: Button, hover: bool):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hover:
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.2)
	else:
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)

	if btn in skin_buttons:
		_update_appearance_display()

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
				$CenterContainer/VBoxContainer/ButtonContainer/RankingButton,
				$CenterContainer/VBoxContainer/ButtonContainer/SkinsButton,
				$CenterContainer/VBoxContainer/ButtonContainer/SettingsButton,
				$SettingsLayer/CenterContainer/VBoxContainer/BackButton,
				$SkinLayer/CenterContainer/VBoxContainer/BackButton,
				ranking_back_btn,
				ranking_length_sort_btn,
				ranking_survival_sort_btn,
				$SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOn,
				$SettingsLayer/CenterContainer/VBoxContainer/CRTSetting/HBoxContainer/CRTOff,
				$SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOn,
				$SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOff]:
		if btn:
			btn.pivot_offset = btn.size / 2

	for btn in skin_buttons:
		if is_instance_valid(btn):
			btn.pivot_offset = btn.size / 2

	# Update ranking smooth scroll
	if ranking_scroll and ranking_scroll.visible and abs(ranking_scroll_velocity) > 0.1:
		var old_v = ranking_scroll.scroll_vertical
		ranking_scroll.scroll_vertical += int(ranking_scroll_velocity * _delta)
		
		# Clamp and bounce/stop if at limits
		var max_scroll = ranking_scroll.get_v_scroll_bar().max_value - ranking_scroll.size.y
		if ranking_scroll.scroll_vertical <= 0 or ranking_scroll.scroll_vertical >= max_scroll:
			ranking_scroll_velocity = 0
		
		ranking_scroll_velocity *= 0.92 # Friction
	else:
		ranking_scroll_velocity = 0

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
