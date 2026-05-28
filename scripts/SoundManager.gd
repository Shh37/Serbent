extends Node

const SFX_BUS_NAME = "SFX"
const MIN_LINEAR_VOLUME = 0.0001
const MAX_AUDIO_PLAYERS = 12

var audio_players: Array[AudioStreamPlayer] = []
var current_player_index: int = 0
var stream_cache: Dictionary = {}
var sfx_bus_index: int = -1

const SFX_EXPLOSION = [
	"res://assets/NES-Sfx_Explosion_01.wav",
	"res://assets/NES-Sfx_Explosion_02.wav",
	"res://assets/NES-Sfx_Explosion_03.wav",
	"res://assets/NES-Sfx_Explosion_04.wav",
]

const SFX_SLASH_HIT = [
	"res://assets/NES-Sfx_Slash_Hit_01.wav",
	"res://assets/NES-Sfx_Slash_Hit_02.wav",
	"res://assets/NES-Sfx_Slash_Hit_03.wav",
]

const SFX_HIT = [
	"res://assets/NES-Sfx_Hit_01.wav",
	"res://assets/NES-Sfx_Hit_02.wav",
	"res://assets/NES-Sfx_Hit_03.wav",
	"res://assets/NES-Sfx_Hit_04.wav",
]

const SFX_UI_SELECT = "res://assets/NES-Sfx_UI_Select_06.wav"
const SFX_UI_SELECT_SUB = "res://assets/NES-Sfx_UI_Select_07.wav"
const SFX_UI_CONFIRM = "res://assets/NES-Sfx_UI_SciFi_Confirm.wav"
const SFX_UI_SUBMIT = "res://assets/NES-Sfx_UI_SciFi_Confirm.wav"
const SFX_UI_POSITIVE = "res://assets/NES-Sfx_UI_Positive_01.wav"
const SFX_UI_NEGATIVE = "res://assets/NES-Sfx_UI_Negative_01.wav"
const SFX_UI_POSITIVE_07 = "res://assets/NES-Sfx_UI_Positive_07.wav"
const SFX_SWEEP_DOWN = "res://assets/NES-Sfx_Sweep_Down_01.wav"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_sfx_bus()
	_preload_streams()

	for i in range(MAX_AUDIO_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS_NAME
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		audio_players.append(player)

	_apply_bus_volume(1.0)

func _ensure_sfx_bus() -> void:
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	if sfx_bus_index != -1:
		return

	sfx_bus_index = AudioServer.bus_count
	AudioServer.add_bus(sfx_bus_index)
	AudioServer.set_bus_name(sfx_bus_index, SFX_BUS_NAME)
	AudioServer.set_bus_send(sfx_bus_index, "Master")

func _preload_streams() -> void:
	var paths: Array[String] = []
	paths.append_array(SFX_EXPLOSION)
	paths.append_array(SFX_SLASH_HIT)
	paths.append_array(SFX_HIT)
	paths.append_array([
		SFX_UI_SELECT,
		SFX_UI_SELECT_SUB,
		SFX_UI_CONFIRM,
		SFX_UI_SUBMIT,
		SFX_UI_POSITIVE,
		SFX_UI_NEGATIVE,
		SFX_UI_POSITIVE_07,
		SFX_SWEEP_DOWN,
	])
	for path in paths:
		_cache_stream(path)

func _cache_stream(path: String) -> void:
	if path.is_empty() or stream_cache.has(path):
		return
	if not ResourceLoader.exists(path):
		push_warning("Missing SFX: %s" % path)
		return

	var stream = load(path)
	if stream is AudioStream:
		stream_cache[path] = stream

func _apply_bus_volume(volume: float) -> void:
	if sfx_bus_index < 0:
		return

	var linear_volume := clampf(volume, 0.0, 1.0)
	if linear_volume <= 0.0:
		AudioServer.set_bus_volume_db(sfx_bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(linear_volume))

func play_explosion() -> void:
	if SFX_EXPLOSION.is_empty():
		return
	play_sound(SFX_EXPLOSION[randi() % SFX_EXPLOSION.size()], 0.6)

func play_slash_hit() -> void:
	if SFX_SLASH_HIT.is_empty():
		return
	play_sound(SFX_SLASH_HIT[randi() % SFX_SLASH_HIT.size()], 0.6)

func play_hit() -> void:
	if SFX_HIT.is_empty():
		return
	play_sound(SFX_HIT[randi() % SFX_HIT.size()])

func play_ui_select() -> void:
	play_sound(SFX_UI_SELECT)

func play_ui_select_sub() -> void:
	play_sound(SFX_UI_SELECT_SUB)

func play_ui_confirm() -> void:
	play_sound(SFX_UI_CONFIRM)

func play_ui_submit() -> void:
	play_sound(SFX_UI_SUBMIT)

func play_ui_positive() -> void:
	play_sound(SFX_UI_POSITIVE)

func play_ui_negative() -> void:
	play_sound(SFX_UI_NEGATIVE)

func play_ui_positive_07() -> void:
	play_sound(SFX_UI_POSITIVE_07, 0.65)

func play_sweep_down() -> void:
	play_sound(SFX_SWEEP_DOWN)

func play_sound(path: String, volume_multiplier: float = 1.0) -> void:
	var stream: AudioStream = stream_cache.get(path)
	if stream == null:
		return

	var player := _acquire_player()
	player.stream = stream
	player.volume_db = linear_to_db(maxf(volume_multiplier, MIN_LINEAR_VOLUME))
	player.play()

func _acquire_player() -> AudioStreamPlayer:
	for player in audio_players:
		if not player.playing:
			return player

	var player := audio_players[current_player_index]
	current_player_index = (current_player_index + 1) % MAX_AUDIO_PLAYERS
	return player

func set_volume(volume: float) -> void:
	_apply_bus_volume(volume)
