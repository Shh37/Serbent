extends Node

signal crt_changed(enabled: bool)
signal beta_upgrades_changed(enabled: bool)
signal fullscreen_changed(enabled: bool)
signal language_changed(language: String)
signal rankings_changed()
signal skin_unlocks_changed()

const SETTINGS_FILE = "user://settings.json"
const RANKING_FILE = "user://rankings.json"
const SKIN_UNLOCK_FILE = "user://skin_unlocks.json"
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
		"body_severing": "BODY SEVERING",
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
		"phantom": "PHANTOM",
		"time_stop": "TIME STOP",
		"double_growth": "DOUBLE GROWTH",
		"how_controls": "- [color=#ea6962]Arrow Keys / WASD[/color] : Turn Snake\n- [color=#ea6962]Opposite Key[/color] : Reverse Snake\n- [color=#ea6962]SPACE (hold) / Double Tap[/color] : Dash",
		"how_rules": "- Goal: Survive [color=#ea6962]longer[/color] and achieve [color=#d8a657]max length[/color]!\n- Eat yellow [color=#d8a657]Points[/color] to grow and score.\n- Collision with [color=#ea6962]Thorns[/color] or your [color=#{snake_color}]own body[/color] is Game Over.",
		"how_severing": "- [color=#ea6962]Bombs/Beams[/color] sever your body - you [color=#7daea3]keep playing[/color]!\n- Severed parts turn into [color=#d8a657]Points[/color].",
		"how_unlocks": "- [color=#d8a657]Colors[/color]: reach target body lengths.\n- [color=#ea6962]Patterns[/color]: reach target survival times."
	},
	LANGUAGE_JA: {
		"play": "あそぶ",
		"ranking": "ランキング",
		"skins": "スキン",
		"how_to_play": "あそびかた",
		"settings": "せってい",
		"crt_shader": "CRTシェーダー",
		"beta_upgrades": "ベータアップグレード",
		"fullscreen": "全画面",
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
		"body_severing": "体が切れる",
		"skin_unlocks": "スキンかいほう",
		"ranking_empty": "ランキングなし",
		"name": "なまえ",
		"best_length": "いちばん長いとき",
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
		"phantom": "ゆうれい",
		"time_stop": "ときとめ",
		"double_growth": "2ばい",
		"how_controls": "- [color=#ea6962]矢印キー / WASD[/color] : 曲がる\n- [color=#ea6962]反対キー[/color] : 引き返す\n- [color=#ea6962]SPACE長押し / 2回タップ[/color] : ダッシュ",
		"how_rules": "- [color=#ea6962]長く[/color]生きて [color=#d8a657]いちばん長いとき[/color]を伸ばす\n- [color=#d8a657]ポイント[/color]を食べると 体が伸びて スコアが増える\n- [color=#ea6962]トゲ[/color]や [color=#{snake_color}]自分の体[/color]に 当たると おわり",
		"how_severing": "- [color=#ea6962]ばくだん/ビーム[/color]で 体が切れる\n  [color=#7daea3]続けられる[/color]\n- 切れた体は [color=#d8a657]ポイント[/color]になる",
		"how_unlocks": "- [color=#d8a657]色[/color]: 体の長さで 増える\n- [color=#ea6962]もよう[/color]: 生きたじかんで 増える"
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

var ranking_entries: Array = []
var skin_unlocks_loaded = false

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready():
	ensure_keyboard_input_actions()
	load_settings()
	load_rankings()
	load_skin_unlocks()

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
		"language": language
	}, "\t"))

signal skin_changed()

var selected_color: GameConstants.SkinColor = GameConstants.SkinColor.BASIC :
	set(value):
		selected_color = value
		skin_changed.emit()
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
		_ensure_default_skin_unlocks()
		skin_unlocks_loaded = true
		return

	var file = FileAccess.open(SKIN_UNLOCK_FILE, FileAccess.READ)
	if not file:
		_ensure_default_skin_unlocks()
		skin_unlocks_loaded = true
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_ensure_default_skin_unlocks()
		skin_unlocks_loaded = true
		return

	unlocked_colors = _normalize_skin_unlock_array(parsed.get("colors", []), GameConstants.SkinColor.values())
	unlocked_patterns = _normalize_skin_unlock_array(parsed.get("patterns", []), GameConstants.SkinPattern.values())
	_ensure_default_skin_unlocks()

	var loaded_selected_color = int(parsed.get("selected_color", GameConstants.SkinColor.BASIC))
	var loaded_selected_pattern = int(parsed.get("selected_pattern", GameConstants.SkinPattern.SOLID))
	selected_color = (loaded_selected_color if loaded_selected_color in unlocked_colors else GameConstants.SkinColor.BASIC) as GameConstants.SkinColor
	selected_pattern = (loaded_selected_pattern if loaded_selected_pattern in unlocked_patterns else GameConstants.SkinPattern.SOLID) as GameConstants.SkinPattern

	if not selected_color in unlocked_colors:
		selected_color = GameConstants.SkinColor.BASIC
	if not selected_pattern in unlocked_patterns:
		selected_pattern = GameConstants.SkinPattern.SOLID
	skin_unlocks_loaded = true

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

func _ensure_default_skin_unlocks(): 
	if not GameConstants.SkinColor.BASIC in unlocked_colors:
		unlocked_colors.append(GameConstants.SkinColor.BASIC)
	if not GameConstants.SkinPattern.SOLID in unlocked_patterns:
		unlocked_patterns.append(GameConstants.SkinPattern.SOLID)

func _normalize_skin_unlock_array(raw_values, allowed_values) -> Array:
	var normalized = []
	if typeof(raw_values) != TYPE_ARRAY:
		return normalized

	for raw_value in raw_values:
		var value = int(raw_value)
		if value in allowed_values and not value in normalized:
			normalized.append(value)
	return normalized

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

	var now = int(Time.get_unix_time_from_system())
	var entry = {
		"id": "%d_%d" % [now, Time.get_ticks_usec()],
		"name": sanitize_player_name(player_name),
		"best_length": max(0, best_length),
		"survival_time": max(0.0, survival_time),
		"created_at": now
	}
	ranking_entries.append(entry)
	_trim_rankings()
	save_rankings()
	rankings_changed.emit()
	return entry

func get_rankings(sort_key: String = "length", limit: int = RANKING_DISPLAY_LIMIT) -> Array:
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
	_trim_rankings()

func save_rankings():
	var file = FileAccess.open(RANKING_FILE, FileAccess.WRITE)
	if not file:
		push_warning("Could not save rankings to %s" % RANKING_FILE)
		return
	file.store_string(JSON.stringify(ranking_entries, "\t"))

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
