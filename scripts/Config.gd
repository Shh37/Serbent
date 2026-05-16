extends Node

signal crt_changed(enabled: bool)
signal beta_upgrades_changed(enabled: bool)
signal rankings_changed()

const RANKING_FILE = "user://rankings.json"
const RANKING_DISPLAY_LIMIT = 200
const RANKING_STORAGE_LIMIT_PER_SORT = 200
const PLAYER_NAME_MAX_LENGTH = 12

var crt_enabled: bool = true :
	set(value):
		crt_enabled = value
		crt_changed.emit(value)

var beta_upgrades_enabled: bool = false :
	set(value):
		beta_upgrades_enabled = value
		beta_upgrades_changed.emit(value)

var ranking_entries: Array = []

func _ready():
	load_rankings()

signal skin_changed()

var selected_color: GameConstants.SkinColor = GameConstants.SkinColor.BASIC :
	set(value):
		selected_color = value
		skin_changed.emit()

var selected_pattern: GameConstants.SkinPattern = GameConstants.SkinPattern.SOLID :
	set(value):
		selected_pattern = value
		skin_changed.emit()

# Achievement-unlocked skins. (Unlocking all for testing/preview)
var unlocked_colors: Array = [
	GameConstants.SkinColor.BASIC,
	GameConstants.SkinColor.MINT,
	GameConstants.SkinColor.OLIVE,
	GameConstants.SkinColor.MOSS,
	GameConstants.SkinColor.LIME,
	GameConstants.SkinColor.EMERALD
]

var unlocked_patterns: Array = [
	GameConstants.SkinPattern.SOLID,
	GameConstants.SkinPattern.STRIPE11,
	GameConstants.SkinPattern.STRIPE12,
	GameConstants.SkinPattern.STRIPE21,
	GameConstants.SkinPattern.STRIPE22,
	GameConstants.SkinPattern.GRADIENT
]

func unlock_color(type: GameConstants.SkinColor):
	if not type in unlocked_colors:
		unlocked_colors.append(type)
		print("Color unlocked: ", type)

func unlock_pattern(type: GameConstants.SkinPattern):
	if not type in unlocked_patterns:
		unlocked_patterns.append(type)
		print("Pattern unlocked: ", type)

func sanitize_player_name(raw_name: String) -> String:
	var clean_name = raw_name.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges()
	if clean_name.is_empty():
		clean_name = "PLAYER"
	if clean_name.length() > PLAYER_NAME_MAX_LENGTH:
		clean_name = clean_name.substr(0, PLAYER_NAME_MAX_LENGTH)
	return clean_name

func format_survival_time(seconds_value: float) -> String:
	var minutes = int(seconds_value) / 60
	var seconds = int(seconds_value) % 60
	var centiseconds = int((seconds_value - int(seconds_value)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]

func add_ranking_entry(player_name: String, best_length: int, survival_time: float) -> Dictionary:
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
