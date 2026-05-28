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
var skin_requirement_label: Label
var skin_requirement_popup: PanelContainer
var skin_requirement_popup_hide_position = Vector2.ZERO
var how_to_play_btn: Button
var how_to_play_back_btn: Button
var language_en_btn: Button
var language_ja_btn: Button
var fullscreen_on_btn: Button
var fullscreen_off_btn: Button
var shared_ranking_on_btn: Button
var shared_ranking_off_btn: Button
var shared_ranking_folder_input: LineEdit
var skin_requirement_tween: Tween
var menu_overlay_transition_in_progress = false
const SKIN_BUTTON_SIZE = Vector2(260, 66)
const SKIN_BUTTON_FONT_SIZE = 32
const RANKING_RANK_COL_WIDTH = 70.0
const RANKING_NAME_COL_WIDTH = 180.0
const RANKING_VALUE_COL_WIDTH = 190.0
const MENU_OVERLAY_STAGGER = 0.055
const MENU_OVERLAY_CENTER_TOP_INSET = 56.0
const MENU_OVERLAY_CONTENT_OFFSET_Y = 38.0
const MENU_OVERLAY_ITEM_OFFSET_Y = 26.0
const MENU_OVERLAY_CONTENT_FADE_TIME = 0.32
const MENU_OVERLAY_CONTENT_MOVE_TIME = 0.52
const MENU_OVERLAY_BACKDROP_FADE_TIME = 0.45
const MENU_OVERLAY_BLUR_TIME = 0.65
const MENU_OVERLAY_ITEM_FADE_TIME = 0.28
const MENU_OVERLAY_ITEM_MOVE_TIME = 0.38
const MENU_OVERLAY_ITEM_DELAY = 0.14

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
	var options_grid = button_container.get_node("OptionsGrid")
	var ranking_btn = _ensure_ranking_button(options_grid)
	ranking_btn.add_theme_font_override("font", font_title)

	how_to_play_btn = $CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/HowToPlayButton
	how_to_play_btn.add_theme_font_override("font", font_title)

	var settings_btn = $CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SettingsButton
	settings_btn.add_theme_font_override("font", font_title)

	var skins_btn = $CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SkinsButton
	skins_btn.add_theme_font_override("font", font_title)

	_ensure_ranking_layer()
	_apply_menu_overlay_centering()

	# How To Play UI elements
	var how_to_play_label = $HowToPlayLayer/CenterContainer/VBoxContainer/Label
	how_to_play_label.add_theme_font_override("font", font_title)
	how_to_play_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var controls_lbl = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsLabel
	controls_lbl.add_theme_font_override("font", font_title)
	controls_lbl.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var controls_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsText
	controls_txt.add_theme_font_override("normal_font", font_text)
	controls_txt.add_theme_color_override("default_color", GameConstants.COLOR_FG)

	var rules_lbl = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesLabel
	rules_lbl.add_theme_font_override("font", font_title)
	rules_lbl.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var rules_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesText
	rules_txt.add_theme_font_override("normal_font", font_text)
	rules_txt.add_theme_color_override("default_color", GameConstants.COLOR_FG)

	var severing_lbl = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringLabel
	severing_lbl.add_theme_font_override("font", font_title)
	severing_lbl.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var severing_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringText
	severing_txt.add_theme_font_override("normal_font", font_text)
	severing_txt.add_theme_color_override("default_color", GameConstants.COLOR_FG)

	var unlocks_lbl = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksLabel
	unlocks_lbl.add_theme_font_override("font", font_title)
	unlocks_lbl.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var unlocks_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksText
	unlocks_txt.add_theme_font_override("normal_font", font_text)
	unlocks_txt.add_theme_color_override("default_color", GameConstants.COLOR_FG)

	how_to_play_back_btn = $HowToPlayLayer/CenterContainer/VBoxContainer/BackButton
	how_to_play_back_btn.add_theme_font_override("font", font_title)
	_apply_how_to_play_layout()

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

	var beta_note = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/RankingNote
	beta_note.add_theme_font_override("font", font_text)
	beta_note.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)

	var beta_on_btn = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOn
	var beta_off_btn = $SettingsLayer/CenterContainer/VBoxContainer/BetaUpgradesSetting/HBoxContainer/BetaOff

	_ensure_language_setting()
	_ensure_fullscreen_setting()
	_ensure_shared_ranking_setting()
	_ensure_shared_ranking_folder_setting()
	_ensure_settings_grid_layout()

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

	_ensure_skin_requirement_label()
	_populate_skin_grids()

	# Set colors using GameConstants (class_name)
	title.add_theme_color_override("default_color", GameConstants.COLOR_FG)

	play_btn.pressed.connect(_on_play_pressed)
	ranking_btn.pressed.connect(_on_ranking_pressed)
	how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	skins_btn.pressed.connect(_on_skins_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	skin_back_btn.pressed.connect(_on_skin_back_pressed)
	ranking_back_btn.pressed.connect(_on_ranking_back_pressed)
	how_to_play_back_btn.pressed.connect(_on_how_to_play_back_pressed)
	ranking_length_sort_btn.pressed.connect(func(): _on_ranking_sort_pressed("length"))
	ranking_survival_sort_btn.pressed.connect(func(): _on_ranking_sort_pressed("survival"))

	for btn in [play_btn, ranking_btn, how_to_play_btn, settings_btn, skins_btn, back_btn, skin_back_btn, ranking_back_btn, how_to_play_back_btn, ranking_length_sort_btn, ranking_survival_sort_btn, crt_on_btn, crt_off_btn, beta_on_btn, beta_off_btn, language_en_btn, language_ja_btn, fullscreen_on_btn, fullscreen_off_btn, shared_ranking_on_btn, shared_ranking_off_btn]:
		btn.add_theme_font_override("font", font_title)
		_setup_standard_button(btn)

		# Connect signals
		btn.mouse_entered.connect(func(): _update_button_style(btn, true))
		btn.mouse_exited.connect(func(): _update_button_style(btn, false))
		btn.button_down.connect(func(): _on_button_down(btn))
		btn.button_up.connect(func(): _on_button_up(btn))

	crt_on_btn.pressed.connect(func(): _on_crt_toggle_pressed(true))
	crt_off_btn.pressed.connect(func(): _on_crt_toggle_pressed(false))
	beta_on_btn.pressed.connect(func(): _on_beta_toggle_pressed(true))
	beta_off_btn.pressed.connect(func(): _on_beta_toggle_pressed(false))
	language_en_btn.pressed.connect(func(): _on_language_pressed(Config.LANGUAGE_EN))
	language_ja_btn.pressed.connect(func(): _on_language_pressed(Config.LANGUAGE_JA))
	fullscreen_on_btn.pressed.connect(func(): _on_fullscreen_toggle_pressed(true))
	fullscreen_off_btn.pressed.connect(func(): _on_fullscreen_toggle_pressed(false))
	shared_ranking_on_btn.pressed.connect(func(): _on_shared_ranking_toggle_pressed(true))
	shared_ranking_off_btn.pressed.connect(func(): _on_shared_ranking_toggle_pressed(false))
	shared_ranking_folder_input.text_submitted.connect(func(_text): _on_shared_ranking_folder_committed(true))
	shared_ranking_folder_input.focus_exited.connect(func(): _on_shared_ranking_folder_committed(false))

	# Signals for dynamically created skin buttons are connected in _populate_skin_grids

	# Sync initial appearance
	_apply_localized_texts()
	_update_appearance_display()
	_refresh_ranking_display()
	Config.rankings_changed.connect(_refresh_ranking_display)
	Config.language_changed.connect(func(_language): _apply_localized_texts())

	# Sync shader visibility
	_update_shader_visibility(Config.crt_enabled)
	_update_crt_buttons_style(Config.crt_enabled)
	Config.crt_changed.connect(_update_shader_visibility)
	Config.crt_changed.connect(_update_crt_buttons_style)

	_update_beta_buttons_style(Config.beta_upgrades_enabled)
	Config.beta_upgrades_changed.connect(_update_beta_buttons_style)
	_update_fullscreen_buttons_style(Config.fullscreen_enabled)
	Config.fullscreen_changed.connect(_update_fullscreen_buttons_style)
	_update_language_buttons_style(Config.language)
	Config.language_changed.connect(_update_language_buttons_style)
	_update_shared_ranking_buttons_style(Config.shared_rankings_enabled)
	Config.shared_rankings_changed.connect(_update_shared_ranking_buttons_style)
	Config.shared_ranking_folder_changed.connect(func(_folder): _sync_shared_ranking_folder_input())

	# Initial style
	for btn in [play_btn, ranking_btn, how_to_play_btn, settings_btn, skins_btn, back_btn, skin_back_btn, ranking_back_btn, how_to_play_back_btn, ranking_length_sort_btn, ranking_survival_sort_btn, crt_on_btn, crt_off_btn, beta_on_btn, beta_off_btn, language_en_btn, language_ja_btn, fullscreen_on_btn, fullscreen_off_btn, shared_ranking_on_btn, shared_ranking_off_btn]:
		btn.pivot_offset = btn.size / 2

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed():
	_sync_shared_ranking_folder_input()
	await _show_menu_overlay($SettingsLayer)

func _on_skins_pressed():
	await _show_menu_overlay($SkinLayer)

func _on_ranking_pressed():
	_refresh_ranking_display()
	await _show_menu_overlay($RankingLayer)

func _on_how_to_play_pressed():
	await _show_menu_overlay($HowToPlayLayer)

func _on_back_pressed():
	await _hide_menu_overlay($SettingsLayer)

func _on_skin_back_pressed():
	_hide_skin_requirement(false)
	await _hide_menu_overlay($SkinLayer)

func _unhandled_key_input(event):
	if Config.is_shortcut_event(event, Config.ACTION_SHORTCUT_MAIN_MENU):
		var overlay = _get_visible_menu_overlay()
		if not overlay:
			return

		get_viewport().set_input_as_handled()
		await _hide_menu_overlay_from_shortcut(overlay)
	elif Config.is_shortcut_event(event, Config.ACTION_SHORTCUT_HOW_TO_PLAY):
		if _get_visible_menu_overlay():
			return

		get_viewport().set_input_as_handled()
		await _play_shortcut_button_press(how_to_play_btn)
		await _on_how_to_play_pressed()
	elif Config.is_shortcut_event(event, &"ui_accept"):
		if _get_visible_menu_overlay() or _has_focused_button():
			return

		get_viewport().set_input_as_handled()
		await _play_shortcut_button_press($CenterContainer/VBoxContainer/ButtonContainer/PlayButton)
		_on_play_pressed()

func _input(event):
	if _handle_ranking_sort_shortcut(event):
		return

	_release_shared_ranking_folder_focus_from_input(event)
	if _should_hide_skin_requirement_from_input(event):
		_hide_skin_requirement(true)

func _handle_ranking_sort_shortcut(event: InputEvent) -> bool:
	if not Config.is_shortcut_event(event, Config.ACTION_SHORTCUT_RANKING_SORT_TOGGLE):
		return false
	if not $RankingLayer.visible:
		return false

	get_viewport().set_input_as_handled()
	_toggle_ranking_sort()
	return true

func _get_visible_menu_overlay() -> CanvasLayer:
	for layer_name in ["SettingsLayer", "SkinLayer", "RankingLayer", "HowToPlayLayer"]:
		var layer = get_node_or_null(layer_name) as CanvasLayer
		if layer and layer.visible:
			return layer
	return null

func _has_focused_button() -> bool:
	var focus_owner = get_viewport().gui_get_focus_owner()
	return focus_owner is Button and focus_owner.is_visible_in_tree()

func _toggle_ranking_sort():
	var next_sort = "survival" if ranking_sort_key == "length" else "length"
	_pulse_shortcut_button(ranking_survival_sort_btn if next_sort == "survival" else ranking_length_sort_btn)
	_on_ranking_sort_pressed(next_sort)

func _hide_menu_overlay_from_shortcut(layer: CanvasLayer):
	if layer.name == "SettingsLayer" and shared_ranking_folder_input and shared_ranking_folder_input.has_focus():
		_on_shared_ranking_folder_committed(true)
	elif layer.name == "SkinLayer":
		_hide_skin_requirement(false)

	await _play_shortcut_button_press(_get_overlay_back_button(layer))
	await _hide_menu_overlay(layer)

func _get_overlay_back_button(layer: CanvasLayer) -> Button:
	if not layer:
		return null
	match layer.name:
		"SettingsLayer":
			return $SettingsLayer/CenterContainer/VBoxContainer/BackButton
		"SkinLayer":
			return $SkinLayer/CenterContainer/VBoxContainer/BackButton
		"RankingLayer":
			return ranking_back_btn
		"HowToPlayLayer":
			return how_to_play_back_btn
	return null

func _pulse_shortcut_button(btn: Button):
	await _play_shortcut_button_press(btn)

func _play_shortcut_button_press(btn: Button):
	if not btn or not is_instance_valid(btn) or btn.disabled:
		return
	btn.grab_focus()
	_on_button_down(btn)
	await get_tree().create_timer(0.08).timeout
	if btn and is_instance_valid(btn):
		_on_button_up(btn)

func _release_shared_ranking_folder_focus_from_input(event: InputEvent):
	if not $SettingsLayer.visible:
		return
	if not shared_ranking_folder_input or not shared_ranking_folder_input.has_focus():
		return

	var click_position = Vector2.ZERO
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		click_position = event.position
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
		click_position = event.position
	else:
		return

	if shared_ranking_folder_input.get_global_rect().has_point(click_position):
		return
	_on_shared_ranking_folder_committed(true)

func _should_hide_skin_requirement_from_input(event: InputEvent) -> bool:
	if not skin_requirement_popup or not skin_requirement_popup.visible:
		return false
	if not $SkinLayer.visible:
		return false

	var click_position = Vector2.ZERO
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return false
		click_position = event.position
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return false
		click_position = event.position
	else:
		return false

	for btn in skin_buttons:
		if is_instance_valid(btn) and btn.get_global_rect().has_point(click_position):
			return false
	return true

func _on_ranking_back_pressed():
	await _hide_menu_overlay($RankingLayer)

func _on_how_to_play_back_pressed():
	await _hide_menu_overlay($HowToPlayLayer)

func _apply_how_to_play_layout():
	var vbox = $HowToPlayLayer/CenterContainer/VBoxContainer
	var row = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer
	var left_col = row.get_node("LeftColumn")
	var right_col = row.get_node("RightColumn")
	var title = $HowToPlayLayer/CenterContainer/VBoxContainer/Label

	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	row.add_theme_constant_override("separation", 48)
	left_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_col.add_theme_constant_override("separation", 16)
	right_col.add_theme_constant_override("separation", 16)

	title.add_theme_font_size_override("font_size", 78)
	for label in [
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksLabel
	]:
		label.add_theme_font_size_override("font_size", 36)

	for rich_text in [
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsText,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesText,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringText,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksText
	]:
		rich_text.custom_minimum_size = Vector2(470, 0)
		rich_text.size_flags_horizontal = Control.SIZE_SHRINK_END
		rich_text.add_theme_font_size_override("normal_font_size", 24)
		rich_text.add_theme_constant_override("line_separation", 3)

	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsText.custom_minimum_size = Vector2(470, 150)
	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringText.custom_minimum_size = Vector2(470, 150)

	how_to_play_back_btn.add_theme_font_size_override("font_size", 40)

func _on_ranking_sort_pressed(sort_key: String):
	ranking_sort_key = sort_key
	_refresh_ranking_display()

func _on_crt_toggle_pressed(enabled: bool):
	Config.crt_enabled = enabled

func _on_beta_toggle_pressed(enabled: bool):
	Config.beta_upgrades_enabled = enabled

func _on_fullscreen_toggle_pressed(enabled: bool):
	Config.fullscreen_enabled = enabled

func _on_shared_ranking_toggle_pressed(enabled: bool):
	Config.shared_rankings_enabled = enabled

func _on_shared_ranking_folder_committed(release_focus: bool):
	if not shared_ranking_folder_input:
		return
	Config.shared_ranking_folder = shared_ranking_folder_input.text
	_sync_shared_ranking_folder_input()
	if release_focus:
		shared_ranking_folder_input.release_focus()

func _on_language_pressed(language: String):
	Config.language = language

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

func _apply_menu_overlay_centering():
	for center in [
		$SettingsLayer/CenterContainer,
		$SkinLayer/CenterContainer,
		$RankingLayer/CenterContainer,
		$HowToPlayLayer/CenterContainer
	]:
		if center:
			center.offset_top = MENU_OVERLAY_CENTER_TOP_INSET
			center.offset_bottom = 0.0

func _show_menu_overlay(layer: CanvasLayer):
	if menu_overlay_transition_in_progress or not layer or layer.visible:
		return

	menu_overlay_transition_in_progress = true
	layer.visible = true

	var blur_bg = layer.get_node_or_null("ColorRect") as ColorRect
	var shade = _ensure_overlay_shade(layer)
	var center = layer.get_node_or_null("CenterContainer") as CenterContainer
	var content = center.get_child(0) as Control if center and center.get_child_count() > 0 else null
	var blur_mat = _get_unique_overlay_blur_material(blur_bg)
	var anim_items = _get_overlay_anim_items(layer, content)

	if blur_bg:
		blur_bg.modulate.a = 0.0
	if shade:
		shade.modulate.a = 0.0
	if blur_mat:
		blur_mat.set_shader_parameter("blur_amount", 2.0)
		blur_mat.set_shader_parameter("tint_color", Color(0.0823529, 0.0823529, 0.0823529, 0.55))
	if content:
		content.modulate.a = 0.0
		content.scale = Vector2(0.96, 0.96)

	for item in anim_items:
		item.modulate.a = 0.0
		item.position.y += MENU_OVERLAY_ITEM_OFFSET_Y

	await get_tree().process_frame

	var target_y = content.position.y if content else 0.0
	if content:
		content.position.y += MENU_OVERLAY_CONTENT_OFFSET_Y
		content.pivot_offset = content.size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	if content:
		tween.tween_property(content, "modulate:a", 1.0, MENU_OVERLAY_CONTENT_FADE_TIME)
		tween.tween_property(content, "position:y", target_y, MENU_OVERLAY_CONTENT_MOVE_TIME)
		tween.tween_property(content, "scale", Vector2.ONE, MENU_OVERLAY_CONTENT_MOVE_TIME)
	if blur_bg:
		tween.tween_property(blur_bg, "modulate:a", 1.0, MENU_OVERLAY_BACKDROP_FADE_TIME)
	if shade:
		tween.tween_property(shade, "modulate:a", 1.0, MENU_OVERLAY_BACKDROP_FADE_TIME)
	if blur_mat:
		tween.tween_property(blur_mat, "shader_parameter/blur_amount", 5.0, MENU_OVERLAY_BLUR_TIME)

	for i in range(anim_items.size()):
		var item = anim_items[i]
		var target_item_y = item.position.y - MENU_OVERLAY_ITEM_OFFSET_Y
		var delay_index = float(item.get_meta("overlay_delay_index", i))
		var delay = MENU_OVERLAY_ITEM_DELAY + delay_index * MENU_OVERLAY_STAGGER
		tween.tween_property(item, "modulate:a", 1.0, MENU_OVERLAY_ITEM_FADE_TIME).set_delay(delay)
		tween.tween_property(item, "position:y", target_item_y, MENU_OVERLAY_ITEM_MOVE_TIME).set_delay(delay)

	await tween.finished
	menu_overlay_transition_in_progress = false

func _hide_menu_overlay(layer: CanvasLayer):
	if menu_overlay_transition_in_progress or not layer or not layer.visible:
		return

	menu_overlay_transition_in_progress = true

	var blur_bg = layer.get_node_or_null("ColorRect") as ColorRect
	var shade = layer.get_node_or_null("ResultShade") as ColorRect
	var center = layer.get_node_or_null("CenterContainer") as CenterContainer
	var content = center.get_child(0) as Control if center and center.get_child_count() > 0 else null
	var blur_mat = _get_unique_overlay_blur_material(blur_bg)
	var original_y = content.position.y if content else 0.0
	if blur_mat:
		blur_mat.set_shader_parameter("blur_amount", 5.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	if content:
		content.pivot_offset = content.size / 2
		tween.tween_property(content, "modulate:a", 0.0, 0.18)
		tween.tween_property(content, "scale", Vector2(0.96, 0.96), 0.18)
		tween.tween_property(content, "position:y", content.position.y - 22.0, 0.18)
	if blur_bg:
		tween.tween_property(blur_bg, "modulate:a", 0.0, 0.26)
	if shade:
		tween.tween_property(shade, "modulate:a", 0.0, 0.26)
	if blur_mat:
		tween.tween_property(blur_mat, "shader_parameter/blur_amount", 0.0, 0.28).set_delay(0.02)

	await tween.finished

	if content:
		content.position.y = original_y
		content.scale = Vector2.ONE
		content.modulate.a = 1.0
	if blur_bg:
		blur_bg.modulate.a = 1.0
	if shade:
		shade.modulate.a = 1.0
	if blur_mat:
		blur_mat.set_shader_parameter("blur_amount", 5.0)

	layer.visible = false
	menu_overlay_transition_in_progress = false

func _get_overlay_anim_items(layer: CanvasLayer, content: Control) -> Array[Control]:
	var items: Array[Control] = []
	if not content:
		return items
	if layer.name == "SkinLayer":
		return _get_skin_overlay_anim_items(content)
	if layer.name == "SettingsLayer":
		return _get_settings_overlay_anim_items(content)
	if layer.name == "HowToPlayLayer":
		return _get_how_to_play_overlay_anim_items(content)
	for child in content.get_children():
		if child is Control:
			items.append(child)
	return items

func _get_settings_overlay_anim_items(content: Control) -> Array[Control]:
	var items: Array[Control] = []
	var title = content.get_node_or_null("Label") as Control
	var grid = content.get_node_or_null("SettingsGrid") as GridContainer
	var back = content.get_node_or_null("BackButton") as Control

	if title:
		title.set_meta("overlay_delay_index", 0)
		items.append(title)
	if grid:
		var setting_order = ["CRTSetting", "BetaUpgradesSetting", "LanguageSetting", "FullscreenSetting", "SharedRankingSetting", "SharedRankingFolderSetting"]
		for i in range(setting_order.size()):
			var setting_name = setting_order[i]
			var item = grid.get_node_or_null(setting_name) as Control
			if item:
				item.set_meta("overlay_delay_index", 1 + floori(float(i) / float(max(1, grid.columns))))
				items.append(item)
	elif content:
		for child in content.get_children():
			if child is Control and child != title and child != back:
				items.append(child)
	if back:
		back.set_meta("overlay_delay_index", 4)
		items.append(back)
	return items

func _get_how_to_play_overlay_anim_items(content: Control) -> Array[Control]:
	var items: Array[Control] = []
	var title = content.get_node_or_null("Label") as Control
	var columns_row = content.get_node_or_null("HBoxContainer") as HBoxContainer
	var left_col = columns_row.get_node_or_null("LeftColumn") as VBoxContainer if columns_row else null
	var right_col = columns_row.get_node_or_null("RightColumn") as VBoxContainer if columns_row else null
	var back = content.get_node_or_null("BackButton") as Control

	if title:
		title.set_meta("overlay_delay_index", 0)
		items.append(title)
	var paired_items = [
		["ControlsLabel", "SeveringLabel", 1],
		["ControlsText", "SeveringText", 1],
		["RulesLabel", "UnlocksLabel", 2],
		["RulesText", "UnlocksText", 2]
	]
	for pair in paired_items:
		var left_item = left_col.get_node_or_null(pair[0]) as Control if left_col else null
		var right_item = right_col.get_node_or_null(pair[1]) as Control if right_col else null
		for item in [left_item, right_item]:
			if item:
				item.set_meta("overlay_delay_index", pair[2])
				items.append(item)
	if back:
		back.set_meta("overlay_delay_index", 3)
		items.append(back)
	return items

func _get_skin_overlay_anim_items(content: Control) -> Array[Control]:
	var items: Array[Control] = []
	var title = content.get_node_or_null("Label") as Control
	var selection_row = content.get_node_or_null("HBoxContainer") as HBoxContainer
	var selection = selection_row.get_node_or_null("SelectionContainer") as VBoxContainer if selection_row else null
	var preview = selection_row.get_node_or_null("PreviewContainer") as Control if selection_row else null
	var back = content.get_node_or_null("BackButton") as Control

	if title:
		title.set_meta("overlay_delay_index", 0)
		items.append(title)
	if selection:
		var grouped_items = {
			"ColorLabel": 1,
			"ColorGrid": 1,
			"PatternLabel": 2,
			"PatternGrid": 2
		}
		for node_name in ["ColorLabel", "ColorGrid", "PatternLabel", "PatternGrid"]:
			var item = selection.get_node_or_null(node_name) as Control
			if item:
				item.set_meta("overlay_delay_index", grouped_items[node_name])
				items.append(item)
	if preview:
		preview.set_meta("overlay_delay_index", 2)
		items.append(preview)
	if back:
		back.set_meta("overlay_delay_index", 3)
		items.append(back)
	return items

func _get_unique_overlay_blur_material(blur_bg: ColorRect) -> ShaderMaterial:
	if not blur_bg or not blur_bg.material:
		return null
	if not bool(blur_bg.get_meta("transition_material_unique", false)):
		blur_bg.material = blur_bg.material.duplicate()
		blur_bg.set_meta("transition_material_unique", true)
	return blur_bg.material as ShaderMaterial

func _ensure_overlay_shade(layer: CanvasLayer) -> ColorRect:
	var existing = layer.get_node_or_null("ResultShade") as ColorRect
	if existing:
		return existing

	var shade = ColorRect.new()
	shade.name = "ResultShade"
	shade.color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.28)
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center = layer.get_node_or_null("CenterContainer")
	if center:
		layer.move_child(shade, center.get_index())
	return shade

func _setup_standard_button(btn: Button):
	_apply_standard_button_size(btn)
	_apply_standard_button_palette(btn)
	btn.focus_mode = Control.FOCUS_ALL

func _apply_standard_button_size(btn: Button):
	var min_width = 0.0
	match btn.name:
		"PlayButton":
			min_width = btn.custom_minimum_size.x
		"CRTOn", "CRTOff", "BetaOn", "BetaOff", "FullscreenOn", "FullscreenOff", "LanguageEnglish", "LanguageJapanese", "SharedRankingOn", "SharedRankingOff":
			min_width = 160.0
		"LengthSortButton", "SurvivalSortButton":
			min_width = 280.0
		"BackButton":
			min_width = 220.0
		"HowToPlayButton":
			min_width = 360.0
		_:
			min_width = 300.0

	if min_width > 0.0:
		btn.custom_minimum_size = Vector2(max(btn.custom_minimum_size.x, min_width), btn.custom_minimum_size.y)

func _apply_button_colors(btn: Button, normal: Color, hover: Color, pressed: Color):
	btn.add_theme_color_override("font_color", normal)
	btn.add_theme_color_override("font_hover_color", hover)
	btn.add_theme_color_override("font_pressed_color", pressed)
	btn.add_theme_color_override("font_focus_color", normal)
	btn.add_theme_color_override("font_disabled_color", GameConstants.COLOR_GHOST)

func _get_button_accent_color() -> Color:
	return GameConstants.SKIN_COLORS.get(Config.selected_color, GameConstants.COLOR_BUTTON_HOVER)

func _apply_standard_button_palette(btn: Button):
	var accent_color = _get_button_accent_color()
	_apply_button_colors(
		btn,
		GameConstants.COLOR_BUTTON_NORMAL,
		accent_color,
		accent_color.darkened(GameConstants.BUTTON_PRESSED_DARKEN)
	)

func _apply_selected_button_colors(btn: Button, selected: bool, selected_color: Color, selected_hover: Color, selected_pressed: Color):
	if selected:
		_apply_button_colors(btn, selected_color, selected_hover, selected_pressed)
	else:
		_apply_button_colors(btn, GameConstants.COLOR_BUTTON_NORMAL, selected_hover, selected_pressed)

func _apply_metric_button_colors(btn: Button, selected: bool, metric_color: Color, metric_hover: Color, metric_pressed: Color):
	if selected:
		_apply_button_colors(btn, metric_color, metric_hover, metric_pressed)
	else:
		_apply_button_colors(btn, GameConstants.COLOR_BUTTON_NORMAL, metric_hover, metric_pressed)

func _get_settings_item(item_name: String) -> VBoxContainer:
	var vbox = $SettingsLayer/CenterContainer/VBoxContainer
	var direct = vbox.get_node_or_null(item_name) as VBoxContainer
	if direct:
		return direct

	var grid = vbox.get_node_or_null("SettingsGrid") as GridContainer
	if grid:
		return grid.get_node_or_null(item_name) as VBoxContainer
	return null

func _ensure_settings_grid_layout():
	var vbox = $SettingsLayer/CenterContainer/VBoxContainer
	vbox.add_theme_constant_override("separation", 38)

	var grid = vbox.get_node_or_null("SettingsGrid") as GridContainer
	if not grid:
		grid = GridContainer.new()
		grid.name = "SettingsGrid"
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.add_theme_constant_override("h_separation", 72)
		grid.add_theme_constant_override("v_separation", 30)
		vbox.add_child(grid)

	var title_label = vbox.get_node_or_null("Label")
	if title_label:
		vbox.move_child(grid, title_label.get_index() + 1)

	var setting_order = ["CRTSetting", "BetaUpgradesSetting", "LanguageSetting", "FullscreenSetting", "SharedRankingSetting", "SharedRankingFolderSetting"]
	for i in range(setting_order.size()):
		var setting_name = setting_order[i]
		var setting = _get_settings_item(setting_name)
		if not setting:
			continue
		if setting.get_parent() != grid:
			setting.reparent(grid, false)
		grid.move_child(setting, i)
		_apply_compact_setting_style(setting)

func _apply_compact_setting_style(setting: VBoxContainer):
	setting.custom_minimum_size = Vector2(370, 0)
	setting.add_theme_constant_override("separation", 10)

	var label = setting.get_node_or_null("Label") as Label
	if label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", font_title)
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_color_override("font_color", GameConstants.COLOR_FG)

	var row = setting.get_node_or_null("HBoxContainer") as HBoxContainer
	if row:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		for child in row.get_children():
			var btn = child as Button
			if btn:
				btn.custom_minimum_size = Vector2(max(btn.custom_minimum_size.x, 160.0), btn.custom_minimum_size.y)
				btn.add_theme_font_size_override("font_size", 36)

	var input = setting.get_node_or_null("FolderInput") as LineEdit
	if input:
		_style_settings_line_edit(input)

	var note = setting.get_node_or_null("RankingNote") as Label
	if note:
		note.custom_minimum_size = Vector2(370, 0)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_override("font", font_text)
		note.add_theme_font_size_override("font_size", 22)
		note.add_theme_color_override("font_color", GameConstants.COLOR_GHOST)

func _update_beta_buttons_style(enabled: bool):
	var beta_setting = _get_settings_item("BetaUpgradesSetting")
	var beta_on_btn = beta_setting.get_node("HBoxContainer/BetaOn") as Button
	var beta_off_btn = beta_setting.get_node("HBoxContainer/BetaOff") as Button

	_apply_selected_button_colors(beta_on_btn, enabled, GameConstants.COLOR_TOGGLE_ON, GameConstants.COLOR_TOGGLE_ON_HOVER, GameConstants.COLOR_TOGGLE_ON_PRESSED)
	_apply_selected_button_colors(beta_off_btn, not enabled, GameConstants.COLOR_TOGGLE_OFF, GameConstants.COLOR_TOGGLE_OFF_HOVER, GameConstants.COLOR_TOGGLE_OFF_PRESSED)

func _update_crt_buttons_style(enabled: bool):
	var crt_setting = _get_settings_item("CRTSetting")
	var crt_on_btn = crt_setting.get_node("HBoxContainer/CRTOn") as Button
	var crt_off_btn = crt_setting.get_node("HBoxContainer/CRTOff") as Button

	_apply_selected_button_colors(crt_on_btn, enabled, GameConstants.COLOR_TOGGLE_ON, GameConstants.COLOR_TOGGLE_ON_HOVER, GameConstants.COLOR_TOGGLE_ON_PRESSED)
	_apply_selected_button_colors(crt_off_btn, not enabled, GameConstants.COLOR_TOGGLE_OFF, GameConstants.COLOR_TOGGLE_OFF_HOVER, GameConstants.COLOR_TOGGLE_OFF_PRESSED)

func _update_fullscreen_buttons_style(enabled: bool):
	if not fullscreen_on_btn or not fullscreen_off_btn:
		return
	_apply_selected_button_colors(fullscreen_on_btn, enabled, GameConstants.COLOR_TOGGLE_ON, GameConstants.COLOR_TOGGLE_ON_HOVER, GameConstants.COLOR_TOGGLE_ON_PRESSED)
	_apply_selected_button_colors(fullscreen_off_btn, not enabled, GameConstants.COLOR_TOGGLE_OFF, GameConstants.COLOR_TOGGLE_OFF_HOVER, GameConstants.COLOR_TOGGLE_OFF_PRESSED)

func _update_shared_ranking_buttons_style(enabled: bool):
	if not shared_ranking_on_btn or not shared_ranking_off_btn:
		return
	_apply_selected_button_colors(shared_ranking_on_btn, enabled, GameConstants.COLOR_TOGGLE_ON, GameConstants.COLOR_TOGGLE_ON_HOVER, GameConstants.COLOR_TOGGLE_ON_PRESSED)
	_apply_selected_button_colors(shared_ranking_off_btn, not enabled, GameConstants.COLOR_TOGGLE_OFF, GameConstants.COLOR_TOGGLE_OFF_HOVER, GameConstants.COLOR_TOGGLE_OFF_PRESSED)
	_update_shared_ranking_folder_input_state(enabled)

func _update_shared_ranking_folder_input_state(enabled: bool):
	if not shared_ranking_folder_input:
		return
	shared_ranking_folder_input.editable = enabled
	shared_ranking_folder_input.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	shared_ranking_folder_input.modulate.a = 1.0 if enabled else 0.56
	if not enabled and shared_ranking_folder_input.has_focus():
		_on_shared_ranking_folder_committed(true)

func _update_language_buttons_style(language: String):
	if not language_en_btn or not language_ja_btn:
		return
	_apply_selected_button_colors(language_en_btn, language == Config.LANGUAGE_EN, GameConstants.COLOR_TOGGLE_ON, GameConstants.COLOR_TOGGLE_ON_HOVER, GameConstants.COLOR_TOGGLE_ON_PRESSED)
	_apply_selected_button_colors(language_ja_btn, language == Config.LANGUAGE_JA, GameConstants.COLOR_TOGGLE_ON, GameConstants.COLOR_TOGGLE_ON_HOVER, GameConstants.COLOR_TOGGLE_ON_PRESSED)

func _ensure_language_setting():
	var vbox = $SettingsLayer/CenterContainer/VBoxContainer
	var existing = _get_settings_item("LanguageSetting")
	if existing:
		language_en_btn = existing.get_node("HBoxContainer/LanguageEnglish") as Button
		language_ja_btn = existing.get_node("HBoxContainer/LanguageJapanese") as Button
		return

	var setting = VBoxContainer.new()
	setting.name = "LanguageSetting"
	setting.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font_title)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	setting.add_child(label)

	var row = HBoxContainer.new()
	row.name = "HBoxContainer"
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	setting.add_child(row)

	language_en_btn = Button.new()
	language_en_btn.name = "LanguageEnglish"
	language_en_btn.flat = true
	language_en_btn.add_theme_font_size_override("font_size", 36)
	row.add_child(language_en_btn)

	language_ja_btn = Button.new()
	language_ja_btn.name = "LanguageJapanese"
	language_ja_btn.flat = true
	language_ja_btn.add_theme_font_size_override("font_size", 36)
	row.add_child(language_ja_btn)

	var back_btn = vbox.get_node_or_null("BackButton")
	vbox.add_child(setting)
	if back_btn:
		vbox.move_child(setting, back_btn.get_index())

func _ensure_fullscreen_setting():
	var vbox = $SettingsLayer/CenterContainer/VBoxContainer
	var existing = _get_settings_item("FullscreenSetting")
	if existing:
		fullscreen_on_btn = existing.get_node("HBoxContainer/FullscreenOn") as Button
		fullscreen_off_btn = existing.get_node("HBoxContainer/FullscreenOff") as Button
		return

	var setting = VBoxContainer.new()
	setting.name = "FullscreenSetting"
	setting.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font_title)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	setting.add_child(label)

	var row = HBoxContainer.new()
	row.name = "HBoxContainer"
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	setting.add_child(row)

	fullscreen_on_btn = Button.new()
	fullscreen_on_btn.name = "FullscreenOn"
	fullscreen_on_btn.flat = true
	fullscreen_on_btn.add_theme_font_size_override("font_size", 36)
	row.add_child(fullscreen_on_btn)

	fullscreen_off_btn = Button.new()
	fullscreen_off_btn.name = "FullscreenOff"
	fullscreen_off_btn.flat = true
	fullscreen_off_btn.add_theme_font_size_override("font_size", 36)
	row.add_child(fullscreen_off_btn)

	var back_btn = vbox.get_node_or_null("BackButton")
	vbox.add_child(setting)
	if back_btn:
		vbox.move_child(setting, back_btn.get_index())

func _ensure_shared_ranking_setting():
	var vbox = $SettingsLayer/CenterContainer/VBoxContainer
	var existing = _get_settings_item("SharedRankingSetting")
	if existing:
		shared_ranking_on_btn = existing.get_node("HBoxContainer/SharedRankingOn") as Button
		shared_ranking_off_btn = existing.get_node("HBoxContainer/SharedRankingOff") as Button
		return

	var setting = VBoxContainer.new()
	setting.name = "SharedRankingSetting"
	setting.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font_title)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	setting.add_child(label)

	var row = HBoxContainer.new()
	row.name = "HBoxContainer"
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	setting.add_child(row)

	shared_ranking_on_btn = Button.new()
	shared_ranking_on_btn.name = "SharedRankingOn"
	shared_ranking_on_btn.flat = true
	shared_ranking_on_btn.add_theme_font_size_override("font_size", 36)
	row.add_child(shared_ranking_on_btn)

	shared_ranking_off_btn = Button.new()
	shared_ranking_off_btn.name = "SharedRankingOff"
	shared_ranking_off_btn.flat = true
	shared_ranking_off_btn.add_theme_font_size_override("font_size", 36)
	row.add_child(shared_ranking_off_btn)

	var back_btn = vbox.get_node_or_null("BackButton")
	vbox.add_child(setting)
	if back_btn:
		vbox.move_child(setting, back_btn.get_index())

func _ensure_shared_ranking_folder_setting():
	var vbox = $SettingsLayer/CenterContainer/VBoxContainer
	var existing = _get_settings_item("SharedRankingFolderSetting")
	if existing:
		shared_ranking_folder_input = existing.get_node("FolderInput") as LineEdit
		return

	var setting = VBoxContainer.new()
	setting.name = "SharedRankingFolderSetting"
	setting.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font_title)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	setting.add_child(label)

	shared_ranking_folder_input = LineEdit.new()
	shared_ranking_folder_input.name = "FolderInput"
	shared_ranking_folder_input.text = Config.shared_ranking_folder
	shared_ranking_folder_input.placeholder_text = Config.DEFAULT_SHARED_RANKING_FOLDER
	_style_settings_line_edit(shared_ranking_folder_input)
	setting.add_child(shared_ranking_folder_input)

	var back_btn = vbox.get_node_or_null("BackButton")
	vbox.add_child(setting)
	if back_btn:
		vbox.move_child(setting, back_btn.get_index())

func _style_settings_line_edit(input: LineEdit):
	input.custom_minimum_size = Vector2(370, 48)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.focus_mode = Control.FOCUS_ALL
	input.caret_blink = true
	input.add_theme_font_override("font", font_text)
	input.add_theme_font_size_override("font_size", 22)
	input.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	input.add_theme_color_override("font_placeholder_color", GameConstants.COLOR_GHOST)
	input.add_theme_color_override("caret_color", GameConstants.COLOR_POINT)
	input.add_theme_color_override("selection_color", Color(GameConstants.COLOR_POINT.r, GameConstants.COLOR_POINT.g, GameConstants.COLOR_POINT.b, 0.35))

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.72)
	normal.border_color = GameConstants.COLOR_GHOST
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(0)
	normal.set_content_margin(SIDE_LEFT, 12)
	normal.set_content_margin(SIDE_RIGHT, 12)
	normal.set_content_margin(SIDE_TOP, 8)
	normal.set_content_margin(SIDE_BOTTOM, 8)

	var focus = normal.duplicate() as StyleBoxFlat
	focus.border_color = GameConstants.COLOR_POINT
	focus.set_border_width_all(3)

	input.add_theme_stylebox_override("normal", normal)
	input.add_theme_stylebox_override("focus", focus)
	input.add_theme_stylebox_override("read_only", normal)

func _sync_shared_ranking_folder_input():
	if not shared_ranking_folder_input or shared_ranking_folder_input.has_focus():
		return
	shared_ranking_folder_input.text = Config.shared_ranking_folder
	shared_ranking_folder_input.placeholder_text = Config.DEFAULT_SHARED_RANKING_FOLDER

func _apply_localized_texts():
	var title_font = font_title
	var body_font = _get_body_font()

	$CenterContainer/VBoxContainer/ButtonContainer/PlayButton.text = Config.tr_text("play")
	$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/RankingButton.text = Config.tr_text("ranking")
	$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SkinsButton.text = Config.tr_text("skins")
	$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/HowToPlayButton.text = Config.tr_text("how_to_play")
	$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SettingsButton.text = Config.tr_text("settings")

	var crt_setting = _get_settings_item("CRTSetting")
	var beta_setting = _get_settings_item("BetaUpgradesSetting")
	var language_setting = _get_settings_item("LanguageSetting")
	var fullscreen_setting = _get_settings_item("FullscreenSetting")
	var shared_ranking_setting = _get_settings_item("SharedRankingSetting")
	var shared_ranking_folder_setting = _get_settings_item("SharedRankingFolderSetting")

	$SettingsLayer/CenterContainer/VBoxContainer/Label.text = Config.tr_text("settings")
	crt_setting.get_node("Label").text = Config.tr_text("crt_shader")
	crt_setting.get_node("HBoxContainer/CRTOn").text = Config.tr_text("on")
	crt_setting.get_node("HBoxContainer/CRTOff").text = Config.tr_text("off")
	beta_setting.get_node("Label").text = Config.tr_text("beta_upgrades")
	beta_setting.get_node("HBoxContainer/BetaOn").text = Config.tr_text("on")
	beta_setting.get_node("HBoxContainer/BetaOff").text = Config.tr_text("off")
	beta_setting.get_node("RankingNote").text = Config.tr_text("beta_upgrades_ranking_note")
	language_setting.get_node("Label").text = Config.tr_text("language")
	language_en_btn.text = Config.tr_text("english")
	language_ja_btn.text = Config.tr_text("japanese")
	fullscreen_setting.get_node("Label").text = Config.tr_text("fullscreen")
	fullscreen_on_btn.text = Config.tr_text("on")
	fullscreen_off_btn.text = Config.tr_text("off")
	shared_ranking_setting.get_node("Label").text = Config.tr_text("shared_ranking")
	shared_ranking_on_btn.text = Config.tr_text("on")
	shared_ranking_off_btn.text = Config.tr_text("off")
	shared_ranking_folder_setting.get_node("Label").text = Config.tr_text("shared_ranking_folder")
	_sync_shared_ranking_folder_input()
	$SettingsLayer/CenterContainer/VBoxContainer/BackButton.text = Config.tr_text("back")

	$SkinLayer/CenterContainer/VBoxContainer/Label.text = Config.tr_text("skin_selection")
	$SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/ColorLabel.text = Config.tr_text("colors")
	$SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/PatternLabel.text = Config.tr_text("patterns")
	$SkinLayer/CenterContainer/VBoxContainer/BackButton.text = Config.tr_text("back")

	$HowToPlayLayer/CenterContainer/VBoxContainer/Label.text = Config.tr_text("how_to_play")
	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsLabel.text = Config.tr_text("controls")
	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesLabel.text = Config.tr_text("rules")
	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringLabel.text = Config.tr_text("body_severing")
	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksLabel.text = Config.tr_text("skin_unlocks")
	$HowToPlayLayer/CenterContainer/VBoxContainer/BackButton.text = Config.tr_text("back")

	for rich_text in [
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsText,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesText,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringText,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksText
	]:
		rich_text.add_theme_font_override("normal_font", body_font)

	$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsText.text = Config.tr_text("how_controls")

	var ranking_layer = get_node_or_null("RankingLayer")
	if ranking_layer:
		ranking_layer.get_node("CenterContainer/VBoxContainer/Label").text = Config.tr_text("ranking")
		ranking_length_sort_btn.text = Config.tr_text("best_length")
		ranking_survival_sort_btn.text = Config.tr_text("survival")
		ranking_empty_label.text = Config.tr_text("ranking_empty")
		_update_ranking_header()
		ranking_back_btn.text = Config.tr_text("back")

	for label in [
		$SettingsLayer/CenterContainer/VBoxContainer/Label,
		crt_setting.get_node("Label"),
		beta_setting.get_node("Label"),
		language_setting.get_node("Label"),
		fullscreen_setting.get_node("Label"),
		shared_ranking_setting.get_node("Label"),
		shared_ranking_folder_setting.get_node("Label"),
		$SkinLayer/CenterContainer/VBoxContainer/Label,
		$SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/ColorLabel,
		$SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/PatternLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/Label,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/ControlsLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringLabel,
		$HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksLabel
	]:
		label.add_theme_font_override("font", title_font)

	_update_appearance_display()
	_refresh_ranking_display()

func _get_body_font() -> Font:
	return font_text

func _update_ranking_header():
	var header = get_node_or_null("RankingLayer/CenterContainer/VBoxContainer/Table/HeaderMargin/Header")
	if not header or header.get_child_count() < 4:
		return
	header.get_child(1).text = Config.tr_text("name")
	header.get_child(2).text = Config.tr_text("best_length")
	header.get_child(3).text = Config.tr_text("survival")

func _ensure_ranking_button(options_grid: GridContainer) -> Button:
	var existing = options_grid.get_node_or_null("RankingButton") as Button
	if existing:
		return existing

	var btn = Button.new()
	btn.name = "RankingButton"
	btn.text = "RANKING"
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 50)
	options_grid.add_child(btn)
	options_grid.move_child(btn, 1)
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
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 22)
	header_margin.add_child(header)
	header.add_child(_create_ranking_cell("#", RANKING_RANK_COL_WIDTH, HORIZONTAL_ALIGNMENT_CENTER, 24, GameConstants.COLOR_GHOST))
	header.add_child(_create_ranking_cell("NAME", RANKING_NAME_COL_WIDTH, HORIZONTAL_ALIGNMENT_LEFT, 24, GameConstants.COLOR_GHOST))
	header.add_child(_create_ranking_cell("BEST LENGTH", RANKING_VALUE_COL_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, 24, GameConstants.COLOR_RANKING_LENGTH))
	header.add_child(_create_ranking_cell("SURVIVAL", RANKING_VALUE_COL_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, 24, GameConstants.COLOR_RANKING_SURVIVAL))

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

	var last_sort_value: float = -1.0
	var current_display_rank: int = 0

	for i in range(entries.size()):
		var entry = entries[i]
		var current_sort_value: float = float(entry.get("best_length", 0)) if ranking_sort_key == "length" else float(entry.get("survival_time", 0.0))

		if i == 0 or not is_equal_approx(current_sort_value, last_sort_value):
			current_display_rank = i + 1
		last_sort_value = current_sort_value

		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 22)
		row.custom_minimum_size = Vector2(700, 36)
		ranking_rows_container.add_child(row)

		var rank_color = GameConstants.COLOR_FG
		var value_color = GameConstants.COLOR_FG
		row.add_child(_create_ranking_cell(str(current_display_rank), RANKING_RANK_COL_WIDTH, HORIZONTAL_ALIGNMENT_CENTER, 28, rank_color))
		row.add_child(_create_ranking_cell(str(entry.get("name", "PLAYER")), RANKING_NAME_COL_WIDTH, HORIZONTAL_ALIGNMENT_LEFT, 28, value_color))
		row.add_child(_create_ranking_cell(str(int(entry.get("best_length", 0))), RANKING_VALUE_COL_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, 28, GameConstants.COLOR_RANKING_LENGTH))
		row.add_child(_create_ranking_cell(Config.format_survival_time(float(entry.get("survival_time", 0.0))), RANKING_VALUE_COL_WIDTH, HORIZONTAL_ALIGNMENT_RIGHT, 28, GameConstants.COLOR_RANKING_SURVIVAL))

func _update_ranking_sort_buttons_style():
	if not ranking_length_sort_btn or not ranking_survival_sort_btn:
		return
	var length_active = ranking_sort_key == "length"
	_apply_metric_button_colors(
		ranking_length_sort_btn,
		length_active,
		GameConstants.COLOR_RANKING_LENGTH,
		GameConstants.COLOR_RANKING_LENGTH_HOVER,
		GameConstants.COLOR_RANKING_LENGTH_PRESSED
	)
	_apply_metric_button_colors(
		ranking_survival_sort_btn,
		not length_active,
		GameConstants.COLOR_RANKING_SURVIVAL,
		GameConstants.COLOR_RANKING_SURVIVAL_HOVER,
		GameConstants.COLOR_RANKING_SURVIVAL_PRESSED
	)

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
		btn.custom_minimum_size = SKIN_BUTTON_SIZE
		btn.flat = true
		btn.pressed.connect(func(): _on_color_selected(c_type, btn))

		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rtl.add_theme_font_override("normal_font", font_title)
		rtl.add_theme_font_size_override("normal_font_size", SKIN_BUTTON_FONT_SIZE)
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
		btn.custom_minimum_size = SKIN_BUTTON_SIZE
		btn.flat = true
		btn.pressed.connect(func(): _on_pattern_selected(p_type, btn))

		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rtl.add_theme_font_override("normal_font", font_title)
		rtl.add_theme_font_size_override("normal_font_size", SKIN_BUTTON_FONT_SIZE)
		rtl.fit_content = true
		rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		center.add_child(rtl)
		btn.add_child(center)

		_setup_skin_button(btn)
		pattern_grid.add_child(btn)
		btn.set_meta("pattern_type", p_type)
		btn.set_meta("base_text", pattern_names.get(p_type, "???"))

func _setup_skin_button(btn: Button):
	btn.set_meta("is_skin_pressed", false)
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_entered.connect(func(): _update_button_style(btn, true))
	btn.mouse_exited.connect(func(): _update_button_style(btn, false))
	btn.button_down.connect(func(): _on_button_down(btn))
	btn.button_up.connect(func(): _on_button_up(btn))
	skin_buttons.append(btn)

func _on_color_selected(c_type, source_button: Button = null):
	if c_type in Config.unlocked_colors:
		Config.selected_color = c_type
		_hide_skin_requirement()
		_update_appearance_display()
	else:
		_show_skin_requirement("%s: %s" % [Config.get_skin_color_name(c_type), Config.get_color_unlock_requirement(c_type)], source_button, GameConstants.COLOR_RANKING_LENGTH)

func _on_pattern_selected(p_type, source_button: Button = null):
	if p_type in Config.unlocked_patterns:
		Config.selected_pattern = p_type
		_hide_skin_requirement()
		_update_appearance_display()
	else:
		_show_skin_requirement("%s: %s" % [Config.get_skin_pattern_name(p_type), Config.get_pattern_unlock_requirement(p_type)], source_button, GameConstants.COLOR_RANKING_SURVIVAL)

func _show_skin_requirement(text: String, source_button: Button = null, text_color: Color = GameConstants.COLOR_FG):
	var label = _ensure_skin_requirement_label()
	var popup = skin_requirement_popup
	label.text = text
	label.add_theme_color_override("font_color", text_color)
	var target_position = _get_skin_requirement_popup_position(source_button, popup.custom_minimum_size)
	skin_requirement_popup_hide_position = _get_skin_requirement_popup_start_position(source_button, target_position, popup.custom_minimum_size)
	popup.position = skin_requirement_popup_hide_position
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.96, 0.96)
	popup.pivot_offset = popup.custom_minimum_size / 2
	popup.visible = true

	if skin_requirement_tween:
		skin_requirement_tween.kill()

	skin_requirement_tween = create_tween()
	skin_requirement_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	skin_requirement_tween.tween_property(popup, "modulate:a", 1.0, 0.12)
	skin_requirement_tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.18)
	skin_requirement_tween.parallel().tween_property(popup, "position", target_position, 0.18)
	skin_requirement_tween.tween_interval(3.0)
	skin_requirement_tween.tween_property(popup, "modulate:a", 0.0, 0.22)
	skin_requirement_tween.parallel().tween_property(popup, "scale", Vector2(0.96, 0.96), 0.22)
	skin_requirement_tween.parallel().tween_property(popup, "position", skin_requirement_popup_hide_position, 0.22)
	skin_requirement_tween.tween_callback(func(): popup.visible = false)

func _hide_skin_requirement(animated: bool = true):
	if skin_requirement_tween:
		skin_requirement_tween.kill()
		skin_requirement_tween = null
	if not skin_requirement_popup or not skin_requirement_popup.visible:
		return
	if not animated:
		skin_requirement_popup.visible = false
		return

	skin_requirement_tween = create_tween()
	skin_requirement_tween.set_parallel(true)
	skin_requirement_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	skin_requirement_tween.tween_property(skin_requirement_popup, "modulate:a", 0.0, 0.16)
	skin_requirement_tween.tween_property(skin_requirement_popup, "scale", Vector2(0.96, 0.96), 0.16)
	skin_requirement_tween.tween_property(skin_requirement_popup, "position", skin_requirement_popup_hide_position, 0.16)
	skin_requirement_tween.chain().tween_callback(func(): skin_requirement_popup.visible = false)

func _get_skin_requirement_popup_position(source_button: Button, popup_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var padding = 18.0
	if not source_button or not is_instance_valid(source_button):
		return Vector2(
			(viewport_size.x - popup_size.x) * 0.5,
			viewport_size.y - popup_size.y - 84.0
		)

	var button_rect = source_button.get_global_rect()
	var pos = Vector2(
		button_rect.position.x + button_rect.size.x + 14.0,
		button_rect.position.y + (button_rect.size.y - popup_size.y) * 0.5
	)
	if pos.x + popup_size.x > viewport_size.x - padding:
		pos.x = button_rect.position.x - popup_size.x - 14.0
	pos.x = clamp(pos.x, padding, viewport_size.x - popup_size.x - padding)
	pos.y = clamp(pos.y, padding, viewport_size.y - popup_size.y - padding)
	return pos

func _get_skin_requirement_popup_start_position(source_button: Button, target_position: Vector2, popup_size: Vector2) -> Vector2:
	if not source_button or not is_instance_valid(source_button):
		return target_position + Vector2(0, 12)

	var button_center = source_button.get_global_rect().get_center()
	var popup_center = target_position + popup_size * 0.5
	var direction = popup_center - button_center
	if direction.length() <= 0.001:
		return target_position
	return target_position - direction.normalized() * 18.0

func _ensure_skin_requirement_label() -> Label:
	if skin_requirement_label:
		return skin_requirement_label

	skin_requirement_popup = PanelContainer.new()
	skin_requirement_popup.name = "SkinRequirementPopup"
	skin_requirement_popup.custom_minimum_size = Vector2(420, 88)
	skin_requirement_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin_requirement_popup.visible = false
	skin_requirement_popup.add_theme_stylebox_override("panel", _create_skin_requirement_panel_style())

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 16)
	skin_requirement_popup.add_child(margin)

	skin_requirement_label = Label.new()
	skin_requirement_label.name = "SkinRequirement"
	skin_requirement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_requirement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skin_requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skin_requirement_label.custom_minimum_size = Vector2(376, 44)
	skin_requirement_label.add_theme_font_override("font", font_title)
	skin_requirement_label.add_theme_font_size_override("font_size", 28)
	skin_requirement_label.add_theme_color_override("font_color", GameConstants.COLOR_FG)
	skin_requirement_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(skin_requirement_label)

	var layer = $SkinLayer
	layer.add_child(skin_requirement_popup)

	var center = layer.get_node_or_null("CenterContainer")
	if center:
		layer.move_child(skin_requirement_popup, center.get_index() + 1)
	return skin_requirement_label

func _create_skin_requirement_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(GameConstants.COLOR_BG.r, GameConstants.COLOR_BG.g, GameConstants.COLOR_BG.b, 0.96)
	style.border_color = GameConstants.COLOR_GHOST
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	return style

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
				char_color = base_color if floori(float(i) * 0.5) % 2 == 0 else darker_color
			GameConstants.SkinPattern.GRADIENT:
				var t = float(i) / float(max(1, text.length() - 1))
				char_color = base_color.lerp(darker_color, t)

		if i == 0:
			char_color = char_color.lightened(0.2)

		bbcode += "[color=#" + char_color.to_html(false) + "]" + text[i] + "[/color]"

	bbcode += "[color=#" + prefix_color + "] <[/color]"
	return bbcode

func _get_skin_button_display_color(btn: Button, base_color: Color) -> Color:
	var display_color = base_color
	if btn.is_hovered():
		display_color = display_color.lightened(GameConstants.BUTTON_SKIN_HOVER_LIGHTEN)
	if bool(btn.get_meta("is_skin_pressed", false)):
		display_color = display_color.darkened(GameConstants.BUTTON_PRESSED_DARKEN)
	return display_color

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
			btn.disabled = false

			var disp_text = text_str
			var prefix_color = base_color.to_html(false) if is_selected else "00000000"

			var color_to_use = GameConstants.SKIN_COLORS[btn_c] if is_unlocked else GameConstants.COLOR_SKIN_LOCKED
			color_to_use = _get_skin_button_display_color(btn, color_to_use)

			rtl.text = "[color=#" + prefix_color + "]> [/color][color=#" + color_to_use.to_html(false) + "]" + disp_text + "[/color][color=#" + prefix_color + "] <[/color]"

	var pattern_grid = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/SelectionContainer/PatternGrid
	if pattern_grid:
		for btn in pattern_grid.get_children():
			var btn_p = btn.get_meta("pattern_type")
			var rtl = btn.get_child(0).get_child(0)
			var text_str = btn.get_meta("base_text")

			var is_selected = (btn_p == p_type)
			var is_unlocked = (btn_p in Config.unlocked_patterns)
			btn.disabled = false

			var disp_text = text_str
			var prefix_color = base_color.to_html(false) if is_selected else "00000000"

			if not is_unlocked:
				var locked_color = _get_skin_button_display_color(btn, GameConstants.COLOR_SKIN_LOCKED)
				rtl.text = "[color=#" + prefix_color + "]> [/color][color=#" + locked_color.to_html(false) + "]" + disp_text + "[/color][color=#" + prefix_color + "] <[/color]"
			else:
				var active_color = _get_skin_button_display_color(btn, base_color)
				rtl.text = get_pattern_bbcode(disp_text, btn_p, active_color, prefix_color)

	# Update Preview
	var preview = $SkinLayer/CenterContainer/VBoxContainer/HBoxContainer/PreviewContainer/SnakePreview
	if preview:
		preview.color_type = c_type
		preview.pattern_type = p_type

	# Keep standard buttons on the shared Gruvbox interaction palette.
	var standard_btns = [
		$CenterContainer/VBoxContainer/ButtonContainer/PlayButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/RankingButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SkinsButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/HowToPlayButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SettingsButton,
		$SettingsLayer/CenterContainer/VBoxContainer/BackButton,
		$SkinLayer/CenterContainer/VBoxContainer/BackButton,
		ranking_back_btn,
		ranking_length_sort_btn,
		ranking_survival_sort_btn,
		how_to_play_back_btn,
		language_en_btn,
		language_ja_btn,
		fullscreen_on_btn,
		fullscreen_off_btn,
		shared_ranking_on_btn,
		shared_ranking_off_btn
	]
	for btn in standard_btns:
		if btn:
			_apply_standard_button_palette(btn)
	_update_ranking_sort_buttons_style()
	_update_crt_buttons_style(Config.crt_enabled)
	_update_beta_buttons_style(Config.beta_upgrades_enabled)
	_update_fullscreen_buttons_style(Config.fullscreen_enabled)
	_update_language_buttons_style(Config.language)
	_update_shared_ranking_buttons_style(Config.shared_rankings_enabled)

	# Dynamic skin color update for HOW TO PLAY text.
	var snake_html = base_color.to_html(false)
	var rich_replacements = {"snake_color": snake_html}
	var rules_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/LeftColumn/RulesText
	if rules_txt:
		rules_txt.text = Config.tr_rich_text("how_rules", rich_replacements)
	var severing_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/SeveringText
	if severing_txt:
		severing_txt.text = Config.tr_rich_text("how_severing", rich_replacements)
	var unlocks_txt = $HowToPlayLayer/CenterContainer/VBoxContainer/HBoxContainer/RightColumn/UnlocksText
	if unlocks_txt:
		unlocks_txt.text = Config.tr_rich_text("how_unlocks", rich_replacements)

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

	var how_to_play_blur = $HowToPlayLayer/ColorRect
	if how_to_play_blur and how_to_play_blur.material:
		how_to_play_blur.material.set_shader_parameter("crt_enabled", enabled)

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
	if btn in skin_buttons:
		btn.set_meta("is_skin_pressed", true)
		_update_appearance_display()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05)
	tween.tween_property(btn, "self_modulate", Color(0.85, 0.85, 0.85), 0.05)

func _on_button_up(btn: Button):
	if btn in skin_buttons:
		btn.set_meta("is_skin_pressed", false)
		_update_appearance_display()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.1, 1.1) if btn.is_hovered() else Vector2(1.0, 1.0)
	tween.tween_property(btn, "scale", target_scale, 0.1)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.1)

func _process(_delta):
	var crt_setting = _get_settings_item("CRTSetting")
	var beta_setting = _get_settings_item("BetaUpgradesSetting")

	# Update pivot offsets
	for btn in [$CenterContainer/VBoxContainer/ButtonContainer/PlayButton,
				$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/RankingButton,
				$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SkinsButton,
				$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/HowToPlayButton,
				$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SettingsButton,
				$SettingsLayer/CenterContainer/VBoxContainer/BackButton,
				$SkinLayer/CenterContainer/VBoxContainer/BackButton,
				ranking_back_btn,
				ranking_length_sort_btn,
				ranking_survival_sort_btn,
				how_to_play_back_btn,
				crt_setting.get_node_or_null("HBoxContainer/CRTOn") if crt_setting else null,
				crt_setting.get_node_or_null("HBoxContainer/CRTOff") if crt_setting else null,
				beta_setting.get_node_or_null("HBoxContainer/BetaOn") if beta_setting else null,
				beta_setting.get_node_or_null("HBoxContainer/BetaOff") if beta_setting else null,
				language_en_btn,
				language_ja_btn,
				fullscreen_on_btn,
				fullscreen_off_btn,
				shared_ranking_on_btn,
				shared_ranking_off_btn]:
		if btn:
			btn.pivot_offset = btn.size / 2

	for btn in skin_buttons:
		if is_instance_valid(btn):
			btn.pivot_offset = btn.size / 2

	# Update ranking smooth scroll
	if ranking_scroll and ranking_scroll.visible and abs(ranking_scroll_velocity) > 0.1:
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
	_update_blur_regions(title)

func _update_blur_regions(_title: Control):
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
		(t_rect.size.x + 56.0) / vp_size.x,  # padding
		(t_rect.size.y + 32.0) / vp_size.y
	)
	mat.set_shader_parameter("title_center", t_center)
	mat.set_shader_parameter("title_size", t_size)

	var buttons = [
		$CenterContainer/VBoxContainer/ButtonContainer/PlayButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SkinsButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/RankingButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/HowToPlayButton,
		$CenterContainer/VBoxContainer/ButtonContainer/OptionsGrid/SettingsButton
	]
	var center_params = ["button_center", "button_center_2", "button_center_3", "button_center_4", "button_center_5"]
	var size_params = ["button_size", "button_size_2", "button_size_3", "button_size_4", "button_size_5"]
	for i in buttons.size():
		var btn = buttons[i] as Control
		if btn and btn.is_visible_in_tree():
			_set_blur_region_from_button(mat, vp_size, btn, center_params[i], size_params[i], Vector2(70.0, 24.0))
		else:
			mat.set_shader_parameter(center_params[i], Vector2(-1.0, -1.0))
			mat.set_shader_parameter(size_params[i], Vector2.ZERO)

func _set_blur_region_from_button(mat: ShaderMaterial, vp_size: Vector2, btn: Button, center_param: String, size_param: String, padding: Vector2):
	var rect = btn.get_global_rect()
	var font = btn.get_theme_font("font")
	var font_size = btn.get_theme_font_size("font_size")
	var text_size = font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size) if font else rect.size
	var visual_size = Vector2(
		text_size.x + padding.x,
		rect.size.y + padding.y
	)
	_set_blur_region(mat, vp_size, Rect2(rect.get_center() - visual_size * 0.5, visual_size), center_param, size_param)

func _set_blur_region(mat: ShaderMaterial, vp_size: Vector2, rect: Rect2, center_param: String, size_param: String):
	var center = Vector2(
		(rect.position.x + rect.size.x * 0.5) / vp_size.x,
		(rect.position.y + rect.size.y * 0.5) / vp_size.y
	)
	var size = Vector2(
		rect.size.x / vp_size.x,
		rect.size.y / vp_size.y
	)
	mat.set_shader_parameter(center_param, center)
	mat.set_shader_parameter(size_param, size)
