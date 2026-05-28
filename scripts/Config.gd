extends Node

signal crt_changed(enabled: bool)
signal beta_upgrades_changed(enabled: bool)
signal fullscreen_changed(enabled: bool)
signal language_changed(language: String)
signal rankings_changed()
signal shared_rankings_changed(enabled: bool)
signal shared_ranking_folder_changed(folder: String)
signal skin_unlocks_changed()

const SETTINGS_FILE = "user://settings.json"
const RANKING_FILE = "user://rankings.json"
const SKIN_UNLOCK_FILE = "user://skin_unlocks.json"
const DEFAULT_SHARED_RANKING_FOLDER = "Y:/Serbent/rankings/entries"
const RANKING_DISPLAY_LIMIT = 200
const RANKING_STORAGE_LIMIT_PER_SORT = 200
const PLAYER_NAME_MAX_LENGTH = 12
const LANGUAGE_EN = "en"
const LANGUAGE_JA = "ja"

const TEXT = {
	LANGUAGE_EN: {
		"play": "PLAY",
		"ranking": "RANKING",
		"skins": "SKINS",
		"how_to_play": "HOW TO PLAY",
		"settings": "SETTINGS",
		"crt_shader": "CRT SHADER",
		"beta_upgrades": "BETA UPGRADES",
		"beta_upgrades_ranking_note": "ON: RANKING ENTRIES\nCANNOT BE ADDED",
		"shared_ranking": "SHARED RANKING",
		"shared_ranking_folder": "RANKING FOLDER",
		"fullscreen": "FULLSCREEN",
		"language": "LANGUAGE",
		"on": "ON",
		"off": "OFF",
		"back": "BACK",
		"english": "ENGLISH",
		"japanese": "JAPANESE",
		"skin_selection": "SKIN SELECTION",
		"colors": "COLORS",
		"patterns": "PATTERNS",
		"controls": "CONTROLS",
		"rules": "RULES",
		"body_severing": "BOMBS & BEAMS",
		"skin_unlocks": "SKIN UNLOCKS",
		"ranking_empty": "NO RANKINGS YET",
		"name": "NAME",
		"best_length": "BEST LENGTH",
		"survival": "SURVIVAL",
		"length": "LENGTH",
		"time": "TIME",
		"results": "RESULTS",
		"run_terminated": "RUN TERMINATED",
		"final_length": "FINAL LENGTH",
		"points": "POINTS",
		"new_skins_unlocked": "NEW SKINS UNLOCKED: ",
		"color": "COLOR",
		"pattern": "PATTERN",
		"add_ranking": "ADD RANKING",
		"submit": "SUBMIT",
		"retry": "RETRY",
		"main_menu": "MAIN MENU",
		"saved": "SAVED",
		"unknown": "UNKNOWN",
		"name_error_empty": "ENTER A NAME",
		"name_error_kanji": "NO KANJI ALLOWED",
		"name_error_duplicate": "NAME ALREADY USED",
		"phantom": "PHANTOM",
		"time_stop": "TIME STOP",
		"double_growth": "DOUBLE GROWTH",
		"dash_hint": "Hold SPACE / press forward twice to dash",
		"reverse_hint": "Press opposite direction to reverse toward your tail",
		"how_controls": "- [color=#d8a657]Arrow Keys / WASD[/color] : Turn\n- [color=#d8a657]Opposite Direction[/color] : Reverse\n- [color=#d8a657]Hold SPACE / Double Tap[/color] : Dash",
		"how_rules": "- Survive [color=#7daea3]as long as you can[/color]\n  and aim for your [color=#{snake_color}]best length[/color].\n- Eat yellow [color=#d8a657]Points[/color]\n  to grow longer.\n- Hitting [color=#ea6962]Thorns[/color] or your\n  [color=#{snake_color}]own body[/color] ends the run.",
		"how_severing": "- [color=#ea6962]Bombs[/color] and [color=#ea6962]Beams[/color] appear sometimes.\n- They cut your [color=#{snake_color}]body[/color] when hit.\n- [color=#d8a657]Points[/color] appear where it was cut.\n- You can keep playing,\n  even after losing that part.",
		"how_unlocks": "- Colors: unlock by reaching\n  [color=#{snake_color}]longer body lengths[/color].\n- Patterns: unlock by surviving\n  [color=#7daea3]longer[/color]."
	},
	LANGUAGE_JA: {
		"play": "あそぶ",
		"ranking": "ランキング",
		"skins": "スキン",
		"how_to_play": "あそびかた",
		"settings": "せってい",
		"crt_shader": "CRTシェーダー",
		"beta_upgrades": "ベータアップグレード",
		"beta_upgrades_ranking_note": "オンにすると\nランキングにのせられません",
		"shared_ranking": "みんなのランキング",
		"shared_ranking_folder": "ランキングフォルダ",
		"fullscreen": "フルスクリーン",
		"language": "言語",
		"on": "オン",
		"off": "オフ",
		"back": "もどる",
		"english": "えいご",
		"japanese": "日本語",
		"skin_selection": "スキン",
		"colors": "いろ",
		"patterns": "もよう",
		"controls": "そうさ",
		"rules": "ルール",
		"body_severing": "ばくだんとビーム",
		"skin_unlocks": "スキンかいほう",
		"ranking_empty": "ランキングなし",
		"name": "なまえ",
		"best_length": "長さきろく",
		"survival": "生きたじかん",
		"length": "長さ",
		"time": "タイム",
		"results": "けっか",
		"run_terminated": "ゲームおわり",
		"final_length": "おわったときの長さ",
		"points": "ポイント",
		"new_skins_unlocked": "あたらしいスキン: ",
		"color": "いろ",
		"pattern": "もよう",
		"add_ranking": "ランキングにのせる",
		"submit": "おくる",
		"retry": "リトライ",
		"main_menu": "メニュー",
		"saved": "ほぞんした",
		"unknown": "ふめい",
		"name_error_empty": "なまえを いれてね",
		"name_error_kanji": "かんじは つかえないよ",
		"name_error_duplicate": "おなじ なまえは つかえないよ",
		"phantom": "ゆうれい",
		"time_stop": "ときとめ",
		"double_growth": "2ばい",
		"dash_hint": "SPACE長おし / 進行方向2回でダッシュ",
		"reverse_hint": "反対キーでしっぽへ切り返し",
		"how_controls": "- [color=#d8a657]矢印キー / WASD[/color] : 向きをかえる\n- [color=#d8a657]反対キー[/color] : ぎゃく向きに進む\n- [color=#d8a657]SPACE長おし / 2回タップ[/color] : ダッシュ",
		"how_rules": "- できるだけ[color=#7daea3]長く生きて[/color]\n  [color=#{snake_color}]いちばん長いからだ[/color]をめざす\n- きいろの[color=#d8a657]ポイント[/color]を食べると\n  からだがのびる\n- [color=#ea6962]トゲ[/color]や[color=#{snake_color}]自分のからだ[/color]に\n  ぶつかるとゲームおわり",
		"how_severing": "- ときどき[color=#ea6962]ばくだん[/color]と[color=#ea6962]ビーム[/color]が出る\n- 当たると[color=#{snake_color}]からだ[/color]が切れる\n- 切れたところに[color=#d8a657]ポイント[/color]が出る\n- 切れてもそのままつづけられる",
		"how_unlocks": "- 色: [color=#{snake_color}]からだを長くする[/color]とふえる\n- もよう: [color=#7daea3]長く生きる[/color]とふえる"
	}
}

const COLOR_UNLOCKS = [
	{"type": GameConstants.SkinColor.BASIC, "threshold": 0, "name": "BASIC"},
	{"type": GameConstants.SkinColor.MINT, "threshold": 10, "name": "MINT"},
	{"type": GameConstants.SkinColor.OLIVE, "threshold": 20, "name": "OLIVE"},
	{"type": GameConstants.SkinColor.MOSS, "threshold": 30, "name": "MOSS"},
	{"type": GameConstants.SkinColor.LIME, "threshold": 40, "name": "LIME"},
	{"type": GameConstants.SkinColor.EMERALD, "threshold": 50, "name": "EMERALD"}
]

const PATTERN_UNLOCKS = [
	{"type": GameConstants.SkinPattern.SOLID, "threshold": 0.0, "name": "SOLID"},
	{"type": GameConstants.SkinPattern.STRIPE11, "threshold": 30.0, "name": "ST1-1"},
	{"type": GameConstants.SkinPattern.STRIPE12, "threshold": 60.0, "name": "ST1-2"},
	{"type": GameConstants.SkinPattern.STRIPE21, "threshold": 90.0, "name": "ST2-1"},
	{"type": GameConstants.SkinPattern.STRIPE22, "threshold": 120.0, "name": "ST2-2"},
	{"type": GameConstants.SkinPattern.GRADIENT, "threshold": 150.0, "name": "GRAD"}
]

var settings_loaded = false

var crt_enabled: bool = true :
	set(value):
		crt_enabled = value
		crt_changed.emit(value)
		if settings_loaded:
			save_settings()

var beta_upgrades_enabled: bool = false :
	set(value):
		beta_upgrades_enabled = value
		beta_upgrades_changed.emit(value)
		if settings_loaded:
			save_settings()

var fullscreen_enabled: bool = false :
	set(value):
		fullscreen_enabled = value
		_apply_fullscreen_setting(value)
		fullscreen_changed.emit(value)
		if settings_loaded:
			save_settings()

var language: String = LANGUAGE_JA :
	set(value):
		var normalized = normalize_language(value)
		if language == normalized:
			return
		language = normalized
		language_changed.emit(language)
		if settings_loaded:
			save_settings()

var shared_rankings_enabled: bool = false :
	set(value):
		if shared_rankings_enabled == value:
			return
		shared_rankings_enabled = value
		shared_rankings_changed.emit(value)
		if settings_loaded:
			save_settings()
			load_rankings()
			rankings_changed.emit()

var shared_ranking_folder: String = DEFAULT_SHARED_RANKING_FOLDER :
	set(value):
		var normalized = normalize_shared_ranking_folder(value)
		if shared_ranking_folder == normalized:
			return
		shared_ranking_folder = normalized
		shared_ranking_folder_changed.emit(shared_ranking_folder)
		if settings_loaded:
			save_settings()
			if shared_rankings_enabled:
				load_rankings()
				rankings_changed.emit()

var ranking_entries: Array = []
var skin_unlocks_loaded = false
var button_focus_style_ready = false

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready():
	ensure_keyboard_input_actions()
	load_settings()
	load_rankings()
	load_skin_unlocks()
	_setup_global_button_focus_style()

func _setup_global_button_focus_style():
	button_focus_style_ready = true
	if not get_tree().node_added.is_connected(_on_global_node_added):
		get_tree().node_added.connect(_on_global_node_added)
	_refresh_global_button_focus_styles()

func _on_global_node_added(node: Node):
	if node is Button:
		_apply_global_button_focus_style(node)

func _refresh_global_button_focus_styles():
	var root = get_tree().root
	if root:
		_apply_global_button_focus_style_recursive(root)

func _apply_global_button_focus_style_recursive(node: Node):
	if node is Button:
		_apply_global_button_focus_style(node)
	for child in node.get_children():
		_apply_global_button_focus_style_recursive(child)

func _apply_global_button_focus_style(button: Button):
	if button.flat:
		button.flat = false
		_apply_transparent_button_styleboxes(button)
	button.add_theme_stylebox_override("focus", _create_global_button_focus_style())
	button.add_theme_color_override("font_focus_color", GameConstants.COLOR_BUTTON_NORMAL)

func _apply_transparent_button_styleboxes(button: Button):
	var normal = _create_transparent_button_style()
	var hover = normal.duplicate() as StyleBoxFlat
	var pressed = normal.duplicate() as StyleBoxFlat
	var disabled = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

func _create_transparent_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	return style

func _create_global_button_focus_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.draw_center = false
	style.border_color = GameConstants.SKIN_COLORS.get(selected_color, GameConstants.COLOR_BUTTON_HOVER)
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)
	style.expand_margin_left = 8
	style.expand_margin_top = 4
	style.expand_margin_right = 8
	style.expand_margin_bottom = 4
	return style

func ensure_keyboard_input_actions():
	var action_keys = {
		"ui_up": [KEY_UP, KEY_W],
		"ui_down": [KEY_DOWN, KEY_S],
		"ui_left": [KEY_LEFT, KEY_A],
		"ui_right": [KEY_RIGHT, KEY_D],
	}

	for action in action_keys.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in action_keys[action]:
			if not _action_has_key(action, keycode):
				var event = InputEventKey.new()
				event.keycode = keycode
				InputMap.action_add_event(action, event)

func _action_has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event = event as InputEventKey
			if key_event.keycode == keycode or key_event.physical_keycode == keycode:
				return true
	return false

func _input(event):
	if _is_fullscreen_toggle_event(event):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func toggle_fullscreen():
	fullscreen_enabled = not is_fullscreen_enabled()

func is_fullscreen_enabled() -> bool:
	var current_mode = DisplayServer.window_get_mode()
	return current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _apply_fullscreen_setting(enabled: bool):
	var target_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)

func _is_fullscreen_toggle_event(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false

	var key_event = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	if key_event.keycode == KEY_F11:
		return true

	return key_event.alt_pressed and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER)

func normalize_language(value: String) -> String:
	return LANGUAGE_JA if value == LANGUAGE_JA else LANGUAGE_EN

func normalize_shared_ranking_folder(value: String) -> String:
	var normalized = value.strip_edges().replace("\\", "/")
	if normalized.is_empty():
		normalized = DEFAULT_SHARED_RANKING_FOLDER

	while normalized.length() > 3 and normalized.ends_with("/"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return normalized

func is_japanese() -> bool:
	return language == LANGUAGE_JA

func tr_text(key: String) -> String:
	var table = TEXT.get(language, TEXT[LANGUAGE_EN])
	return str(table.get(key, TEXT[LANGUAGE_EN].get(key, key)))

func tr_rich_text(key: String, replacements: Dictionary = {}) -> String:
	var text = tr_text(key)
	for replace_key in replacements.keys():
		text = text.replace("{%s}" % str(replace_key), str(replacements[replace_key]))
	return text

func load_settings():
	settings_loaded = false
	if not FileAccess.file_exists(SETTINGS_FILE):
		settings_loaded = true
		save_settings()
		return

	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if not file:
		settings_loaded = true
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		settings_loaded = true
		save_settings()
		return

	crt_enabled = bool(parsed.get("crt_enabled", true))
	beta_upgrades_enabled = bool(parsed.get("beta_upgrades_enabled", false))
	fullscreen_enabled = bool(parsed.get("fullscreen_enabled", is_fullscreen_enabled()))
	language = normalize_language(str(parsed.get("language", LANGUAGE_JA)))
	shared_rankings_enabled = bool(parsed.get("shared_rankings_enabled", false))
	shared_ranking_folder = normalize_shared_ranking_folder(str(parsed.get("shared_ranking_folder", DEFAULT_SHARED_RANKING_FOLDER)))
	settings_loaded = true

func save_settings():
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if not file:
		push_warning("Could not save settings to %s" % SETTINGS_FILE)
		return

	file.store_string(JSON.stringify({
		"crt_enabled": crt_enabled,
		"beta_upgrades_enabled": beta_upgrades_enabled,
		"fullscreen_enabled": fullscreen_enabled,
		"language": language,
		"shared_rankings_enabled": shared_rankings_enabled,
		"shared_ranking_folder": shared_ranking_folder
	}, "\t"))

signal skin_changed()

var selected_color: GameConstants.SkinColor = GameConstants.SkinColor.BASIC :
	set(value):
		selected_color = value
		skin_changed.emit()
		if button_focus_style_ready:
			_refresh_global_button_focus_styles()
		if skin_unlocks_loaded:
			save_skin_unlocks()

var selected_pattern: GameConstants.SkinPattern = GameConstants.SkinPattern.SOLID :
	set(value):
		selected_pattern = value
		skin_changed.emit()
		if skin_unlocks_loaded:
			save_skin_unlocks()

# Achievement-unlocked skins.
var unlocked_colors: Array = [
	GameConstants.SkinColor.BASIC
]

var unlocked_patterns: Array = [
	GameConstants.SkinPattern.SOLID
]

func unlock_color(type: GameConstants.SkinColor, save_now: bool = true) -> bool:
	if not type in unlocked_colors:
		unlocked_colors.append(type)
		print("Color unlocked: ", type)
		if save_now:
			save_skin_unlocks()
			skin_unlocks_changed.emit()
		return true
	return false

func unlock_pattern(type: GameConstants.SkinPattern, save_now: bool = true) -> bool:
	if not type in unlocked_patterns:
		unlocked_patterns.append(type)
		print("Pattern unlocked: ", type)
		if save_now:
			save_skin_unlocks()
			skin_unlocks_changed.emit()
		return true
	return false

func unlock_skins_for_run(longest_length: int, survival_time: float) -> Dictionary:
	var newly_unlocked = {
		"colors": [],
		"patterns": []
	}

	for unlock in COLOR_UNLOCKS:
		if longest_length >= int(unlock["threshold"]) and unlock_color(unlock["type"], false):
			newly_unlocked["colors"].append(unlock)

	for unlock in PATTERN_UNLOCKS:
		if survival_time >= float(unlock["threshold"]) and unlock_pattern(unlock["type"], false):
			newly_unlocked["patterns"].append(unlock)

	if not newly_unlocked["colors"].is_empty() or not newly_unlocked["patterns"].is_empty():
		save_skin_unlocks()
		skin_unlocks_changed.emit()

	return newly_unlocked

func get_skin_color_name(type: GameConstants.SkinColor) -> String:
	for unlock in COLOR_UNLOCKS:
		if unlock["type"] == type:
			return unlock["name"]
	return "???"

func get_skin_pattern_name(type: GameConstants.SkinPattern) -> String:
	for unlock in PATTERN_UNLOCKS:
		if unlock["type"] == type:
			return unlock["name"]
	return "???"

func get_color_unlock_info(type: GameConstants.SkinColor) -> Dictionary:
	return _get_unlock_info(COLOR_UNLOCKS, type)

func get_pattern_unlock_info(type: GameConstants.SkinPattern) -> Dictionary:
	return _get_unlock_info(PATTERN_UNLOCKS, type)

func get_color_unlock_requirement(type: GameConstants.SkinColor) -> String:
	var unlock = get_color_unlock_info(type)
	if unlock.is_empty():
		return tr_text("unknown")
	return "%s %d" % [tr_text("length"), int(unlock.get("threshold", 0))]

func get_pattern_unlock_requirement(type: GameConstants.SkinPattern) -> String:
	var unlock = get_pattern_unlock_info(type)
	if unlock.is_empty():
		return tr_text("unknown")
	return "%s %s" % [tr_text("time"), format_survival_time(float(unlock.get("threshold", 0.0)))]

func load_skin_unlocks():
	skin_unlocks_loaded = false
	if not FileAccess.file_exists(SKIN_UNLOCK_FILE):
		_reset_skin_unlocks_to_default()
		skin_unlocks_loaded = true
		save_skin_unlocks()
		return

	var file = FileAccess.open(SKIN_UNLOCK_FILE, FileAccess.READ)
	if not file:
		_reset_skin_unlocks_to_default()
		skin_unlocks_loaded = true
		push_warning("Could not load skin unlocks from %s" % SKIN_UNLOCK_FILE)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_reset_skin_unlocks_to_default()
		skin_unlocks_loaded = true
		push_warning("Skin unlock data was invalid. Resetting to default skin.")
		save_skin_unlocks()
		return

	var needs_repair = false
	var raw_colors = parsed.get("colors", [])
	var raw_patterns = parsed.get("patterns", [])
	unlocked_colors = _normalize_skin_unlock_array(raw_colors, GameConstants.SkinColor.values())
	unlocked_patterns = _normalize_skin_unlock_array(raw_patterns, GameConstants.SkinPattern.values())
	needs_repair = needs_repair or _skin_unlock_array_needs_repair(raw_colors, unlocked_colors)
	needs_repair = needs_repair or _skin_unlock_array_needs_repair(raw_patterns, unlocked_patterns)
	needs_repair = _ensure_default_skin_unlocks() or needs_repair

	var loaded_selected_color = _parse_skin_value(
		parsed.get("selected_color", null),
		null,
		GameConstants.SkinColor.values()
	)
	var loaded_selected_pattern = _parse_skin_value(
		parsed.get("selected_pattern", null),
		null,
		GameConstants.SkinPattern.values()
	)
	if loaded_selected_color == null or not loaded_selected_color in unlocked_colors:
		loaded_selected_color = GameConstants.SkinColor.BASIC
		needs_repair = true
	if loaded_selected_pattern == null or not loaded_selected_pattern in unlocked_patterns:
		loaded_selected_pattern = GameConstants.SkinPattern.SOLID
		needs_repair = true

	selected_color = loaded_selected_color as GameConstants.SkinColor
	selected_pattern = loaded_selected_pattern as GameConstants.SkinPattern

	if not selected_color in unlocked_colors:
		selected_color = GameConstants.SkinColor.BASIC
		needs_repair = true
	if not selected_pattern in unlocked_patterns:
		selected_pattern = GameConstants.SkinPattern.SOLID
		needs_repair = true
	skin_unlocks_loaded = true
	if needs_repair:
		push_warning("Skin unlock data was repaired.")
		save_skin_unlocks()

func save_skin_unlocks():
	var file = FileAccess.open(SKIN_UNLOCK_FILE, FileAccess.WRITE)
	if not file:
		push_warning("Could not save skin unlocks to %s" % SKIN_UNLOCK_FILE)
		return

	file.store_string(JSON.stringify({
		"colors": unlocked_colors,
		"patterns": unlocked_patterns,
		"selected_color": selected_color,
		"selected_pattern": selected_pattern
	}, "\t"))

func _reset_skin_unlocks_to_default():
	unlocked_colors = [GameConstants.SkinColor.BASIC]
	unlocked_patterns = [GameConstants.SkinPattern.SOLID]
	selected_color = GameConstants.SkinColor.BASIC
	selected_pattern = GameConstants.SkinPattern.SOLID

func _ensure_default_skin_unlocks() -> bool:
	var changed = false
	if not GameConstants.SkinColor.BASIC in unlocked_colors:
		unlocked_colors.append(GameConstants.SkinColor.BASIC)
		changed = true
	if not GameConstants.SkinPattern.SOLID in unlocked_patterns:
		unlocked_patterns.append(GameConstants.SkinPattern.SOLID)
		changed = true
	return changed

func _normalize_skin_unlock_array(raw_values, allowed_values) -> Array:
	var normalized = []
	if typeof(raw_values) != TYPE_ARRAY:
		return normalized

	for raw_value in raw_values:
		var value = _parse_skin_value(raw_value, null, allowed_values)
		if value == null:
			continue
		if value in allowed_values and not value in normalized:
			normalized.append(value)
	return normalized

func _skin_unlock_array_needs_repair(raw_values, normalized_values: Array) -> bool:
	if typeof(raw_values) != TYPE_ARRAY:
		return true
	return raw_values.size() != normalized_values.size()

func _parse_skin_value(raw_value, fallback, allowed_values):
	var value
	match typeof(raw_value):
		TYPE_INT:
			value = raw_value
		TYPE_FLOAT:
			if raw_value != float(int(raw_value)):
				return fallback
			value = int(raw_value)
		TYPE_STRING:
			if not raw_value.is_valid_int():
				return fallback
			value = int(raw_value)
		_:
			return fallback

	return value if value in allowed_values else fallback

func _get_unlock_info(unlocks: Array, type: int) -> Dictionary:
	for unlock in unlocks:
		if int(unlock.get("type", -1)) == type:
			return unlock
	return {}

func sanitize_player_name(raw_name: String) -> String:
	var clean_name = raw_name.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges()
	if clean_name.is_empty():
		clean_name = "PLAYER"
	if clean_name.length() > PLAYER_NAME_MAX_LENGTH:
		clean_name = clean_name.substr(0, PLAYER_NAME_MAX_LENGTH)
	return clean_name

## なまえのバリデーション
## 戻り値: "" = OK, それ以外 = エラー理由キー
func validate_player_name(raw_name: String) -> String:
	if shared_rankings_enabled:
		load_rankings()

	var stripped = raw_name.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges()
	# ルール1: 1文字以上（空・スペースのみ NG）
	if stripped.is_empty():
		return "name_error_empty"
	# ルール2: 漢字を含んでいない（CJK統合漢字 U+4E00〜U+9FFF）
	for i in range(stripped.length()):
		var code = stripped.unicode_at(i)
		if code >= 0x4E00 and code <= 0x9FFF:
			return "name_error_kanji"
		# CJK拡張A U+3400〜U+4DBF
		if code >= 0x3400 and code <= 0x4DBF:
			return "name_error_kanji"
	# ルール3: 既存ランキングに同じ名前がない（大文字小文字を区別しない）
	var stripped_lower = stripped.to_lower()
	for entry in ranking_entries:
		if str(entry.get("name", "")).to_lower() == stripped_lower:
			return "name_error_duplicate"
	return ""

func get_name_error_text(error_key: String) -> String:
	return tr_text(error_key)

func format_survival_time(seconds_value: float) -> String:
	var minutes = floori(seconds_value / 60.0)
	var seconds = int(seconds_value) % 60
	var centiseconds = int((seconds_value - int(seconds_value)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]

func can_add_ranking_entry() -> bool:
	return not beta_upgrades_enabled

func add_ranking_entry(player_name: String, best_length: int, survival_time: float) -> Dictionary:
	if not can_add_ranking_entry():
		push_warning("Ranking entries are disabled while beta upgrades are enabled.")
		return {}

	if shared_rankings_enabled:
		load_rankings()

	var now = int(Time.get_unix_time_from_system())
	var entry = {
		"id": _make_ranking_entry_id(now),
		"name": sanitize_player_name(player_name),
		"best_length": max(0, best_length),
		"survival_time": max(0.0, survival_time),
		"created_at": now
	}
	ranking_entries.append(entry)
	_trim_rankings()
	if shared_rankings_enabled and _save_shared_ranking_entry(entry):
		load_rankings()
	else:
		save_rankings()
	rankings_changed.emit()
	return entry

func get_rankings(sort_key: String = "length", limit: int = RANKING_DISPLAY_LIMIT) -> Array:
	if shared_rankings_enabled:
		load_rankings()

	var sorted_entries = _get_sorted_entries(sort_key)
	var display_entries = []
	for i in range(min(limit, sorted_entries.size())):
		display_entries.append(sorted_entries[i])
	return display_entries

func get_length_rank(best_length: int, survival_time: float = 0.0) -> int:
	return _get_candidate_rank({
		"best_length": best_length,
		"survival_time": survival_time,
		"created_at": int(Time.get_unix_time_from_system())
	}, "length")

func get_survival_rank(survival_time: float, best_length: int = 0) -> int:
	return _get_candidate_rank({
		"best_length": best_length,
		"survival_time": survival_time,
		"created_at": int(Time.get_unix_time_from_system())
	}, "survival")

func load_rankings():
	ranking_entries.clear()
	if shared_rankings_enabled and _load_shared_rankings():
		return
	_load_local_rankings()

func _load_local_rankings():
	if not FileAccess.file_exists(RANKING_FILE):
		return

	var file = FileAccess.open(RANKING_FILE, FileAccess.READ)
	if not file:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return

	for raw_entry in parsed:
		if typeof(raw_entry) == TYPE_DICTIONARY:
			ranking_entries.append(_normalize_ranking_entry(raw_entry))
	_deduplicate_rankings()
	_trim_rankings()

func save_rankings():
	var file = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	if not file:
		push_warning("Could not save rankings to %s" % RANKING_FILE)
		return
	file.store_string(JSON.stringify(ranking_entries, "\t"))

func _load_shared_rankings() -> bool:
	if not _ensure_shared_ranking_folder():
		return false

	var dir = DirAccess.open(shared_ranking_folder)
	if not dir:
		push_warning("Could not open shared ranking folder: %s" % shared_ranking_folder)
		return false

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
			_load_shared_ranking_file(_join_path(shared_ranking_folder, file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	_deduplicate_rankings()
	_trim_rankings()
	return true

func _load_shared_ranking_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		ranking_entries.append(_normalize_ranking_entry(parsed))
	elif typeof(parsed) == TYPE_ARRAY:
		for raw_entry in parsed:
			if typeof(raw_entry) == TYPE_DICTIONARY:
				ranking_entries.append(_normalize_ranking_entry(raw_entry))

func _save_shared_ranking_entry(entry: Dictionary) -> bool:
	if not _ensure_shared_ranking_folder():
		return false

	for attempt in range(8):
		var file_name = _make_shared_ranking_file_name(entry, attempt)
		var final_path = _join_path(shared_ranking_folder, file_name)
		if FileAccess.file_exists(final_path):
			continue

		var temp_path = "%s.tmp" % final_path
		var file = FileAccess.open(temp_path, FileAccess.WRITE)
		if not file:
			push_warning("Could not save shared ranking temp file: %s" % temp_path)
			return false

		file.store_string(JSON.stringify(entry, "\t"))
		file = null

		var rename_error = DirAccess.rename_absolute(temp_path, final_path)
		if rename_error == OK:
			return true

		DirAccess.remove_absolute(temp_path)

	push_warning("Could not save shared ranking entry to %s" % shared_ranking_folder)
	return false

func _ensure_shared_ranking_folder() -> bool:
	if DirAccess.dir_exists_absolute(shared_ranking_folder):
		return true

	var error = DirAccess.make_dir_recursive_absolute(shared_ranking_folder)
	if error != OK:
		push_warning("Could not create shared ranking folder: %s" % shared_ranking_folder)
		return false
	return true

func _join_path(folder: String, file_name: String) -> String:
	if folder.ends_with("/"):
		return "%s%s" % [folder, file_name]
	return "%s/%s" % [folder, file_name]

func _make_ranking_entry_id(created_at: int) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return "%d_%d_%d" % [created_at, Time.get_ticks_usec(), rng.randi()]

func _make_shared_ranking_file_name(entry: Dictionary, attempt: int) -> String:
	var entry_id = str(entry.get("id", ""))
	if attempt > 0:
		entry_id = "%s_%d" % [entry_id, attempt]
	return "%s.json" % entry_id

func _normalize_ranking_entry(raw_entry: Dictionary) -> Dictionary:
	var best_length = int(raw_entry.get("best_length", raw_entry.get("length", 0)))
	var survival_time = float(raw_entry.get("survival_time", raw_entry.get("time", 0.0)))
	var created_at = int(raw_entry.get("created_at", 0))
	var entry_id = str(raw_entry.get("id", ""))
	if entry_id.is_empty():
		entry_id = "%s_%d_%d_%d" % [
			sanitize_player_name(str(raw_entry.get("name", "PLAYER"))),
			best_length,
			int(survival_time * 100.0),
			created_at
		]
	return {
		"id": entry_id,
		"name": sanitize_player_name(str(raw_entry.get("name", "PLAYER"))),
		"best_length": max(0, best_length),
		"survival_time": max(0.0, survival_time),
		"created_at": created_at
	}

func _get_sorted_entries(sort_key: String) -> Array:
	var sorted_entries = ranking_entries.duplicate(true)
	sorted_entries.sort_custom(func(a, b): return _ranking_entry_before(a, b, sort_key))
	return sorted_entries

func _get_candidate_rank(candidate: Dictionary, sort_key: String) -> int:
	if shared_rankings_enabled:
		load_rankings()

	var rank = 1
	for entry in ranking_entries:
		if _ranking_entry_before(entry, candidate, sort_key):
			rank += 1
	return rank

func _ranking_entry_before(a: Dictionary, b: Dictionary, sort_key: String) -> bool:
	var a_length = int(a.get("best_length", 0))
	var b_length = int(b.get("best_length", 0))
	var a_survival = float(a.get("survival_time", 0.0))
	var b_survival = float(b.get("survival_time", 0.0))

	if sort_key == "survival":
		if not is_equal_approx(a_survival, b_survival):
			return a_survival > b_survival
		if a_length != b_length:
			return a_length > b_length
	else:
		if a_length != b_length:
			return a_length > b_length
		if not is_equal_approx(a_survival, b_survival):
			return a_survival > b_survival

	return int(a.get("created_at", 0)) < int(b.get("created_at", 0))

func _deduplicate_rankings():
	var seen_ids = {}
	var unique_entries = []
	for entry in ranking_entries:
		var entry_id = str(entry.get("id", ""))
		if entry_id.is_empty():
			entry_id = _make_ranking_entry_id(int(entry.get("created_at", 0)))
			entry["id"] = entry_id
		if seen_ids.has(entry_id):
			continue
		seen_ids[entry_id] = true
		unique_entries.append(entry)
	ranking_entries = unique_entries

func _trim_rankings():
	if ranking_entries.size() <= RANKING_STORAGE_LIMIT_PER_SORT:
		return

	var kept_entries = []
	var seen_ids = {}
	for sort_key in ["length", "survival"]:
		var sorted_entries = _get_sorted_entries(sort_key)
		for i in range(min(RANKING_STORAGE_LIMIT_PER_SORT, sorted_entries.size())):
			var entry = sorted_entries[i]
			var entry_id = str(entry.get("id", ""))
			if not seen_ids.has(entry_id):
				seen_ids[entry_id] = true
				kept_entries.append(entry)

	ranking_entries = kept_entries
