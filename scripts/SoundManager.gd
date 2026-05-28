extends Node

var audio_players: Array[AudioStreamPlayer] = []
var max_audio_players: int = 8
var current_player_index: int = 0
var sfx_volume: float = 1.0

# Sound paths
const SFX_EXPLOSION = [
	"res://assets/NES-Sfx_Explosion_01.wav",
	"res://assets/NES-Sfx_Explosion_02.wav",
	"res://assets/NES-Sfx_Explosion_03.wav",
	"res://assets/NES-Sfx_Explosion_04.wav"
]

const SFX_SLASH_HIT = [
	"res://assets/NES-Sfx_Slash_Hit_01.wav",
	"res://assets/NES-Sfx_Slash_Hit_02.wav",
	"res://assets/NES-Sfx_Slash_Hit_03.wav"
]

const SFX_HIT = [
	"res://assets/NES-Sfx_Hit_01.wav",
	"res://assets/NES-Sfx_Hit_02.wav",
	"res://assets/NES-Sfx_Hit_03.wav",
	"res://assets/NES-Sfx_Hit_04.wav"
]

const SFX_UI_SELECT = "res://assets/NES-Sfx_UI_Select_06.wav"
const SFX_UI_SELECT_SUB = "res://assets/NES-Sfx_UI_Select_07.wav"
const SFX_UI_CONFIRM = "res://assets/NES-Sfx_UI_SciFi_Confirm.wav"
const SFX_UI_SUBMIT = "res://assets/NES-Sfx_UI_SciFi_Confirm.wav"
const SFX_UI_POSITIVE = "res://assets/NES-Sfx_UI_Positive_01.wav"
const SFX_UI_NEGATIVE = "res://assets/NES-Sfx_UI_Negative_01.wav"
const SFX_UI_POSITIVE_07 = "res://assets/NES-Sfx_UI_Positive_07.wav"
const SFX_SWEEP_DOWN = "res://assets/NES-Sfx_Sweep_Down_01.wav"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Create multiple audio players for simultaneous sound playback
	for i in range(max_audio_players):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sfx_volume)
		player.bus = "Master"  # Use Master bus to avoid pause issues
		player.process_mode = Node.PROCESS_MODE_ALWAYS  # Play even when paused
		add_child(player)
		audio_players.append(player)

func play_explosion():
	if SFX_EXPLOSION.is_empty():
		return
	var random_idx = randi() % SFX_EXPLOSION.size()
	play_sound(SFX_EXPLOSION[random_idx], 0.6)  # 60% volume

func play_slash_hit():
	if SFX_SLASH_HIT.is_empty():
		return
	var random_idx = randi() % SFX_SLASH_HIT.size()
	play_sound(SFX_SLASH_HIT[random_idx], 0.6)  # 60% volume

func play_hit():
	if SFX_HIT.is_empty():
		return
	var random_idx = randi() % SFX_HIT.size()
	play_sound(SFX_HIT[random_idx])

func play_ui_select():
	play_sound(SFX_UI_SELECT)

func play_ui_select_sub():
	play_sound(SFX_UI_SELECT_SUB)

func play_ui_confirm():
	play_sound(SFX_UI_CONFIRM)

func play_ui_submit():
	play_sound(SFX_UI_SUBMIT)

func play_ui_positive():
	play_sound(SFX_UI_POSITIVE)

func play_ui_negative():
	play_sound(SFX_UI_NEGATIVE)

func play_ui_positive_07():
	play_sound(SFX_UI_POSITIVE_07, 0.65)  # 65% volume

func play_sweep_down():
	play_sound(SFX_SWEEP_DOWN)

func play_sound(path: String, volume_multiplier: float = 1.0):
	if not FileAccess.file_exists(path):
		return
	
	var stream = load(path)
	if not (stream is AudioStream):
		return
	
	# Find an available audio player (not currently playing)
	var player: AudioStreamPlayer = null
	for p in audio_players:
		if not p.playing:
			player = p
			break
	
	# If all players are busy, use the next one in rotation
	if player == null:
		player = audio_players[current_player_index]
		current_player_index = (current_player_index + 1) % max_audio_players
	
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * volume_multiplier)
	player.play()

func set_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	for player in audio_players:
		player.volume_db = linear_to_db(sfx_volume)
