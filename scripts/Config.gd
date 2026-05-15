extends Node

signal crt_changed(enabled: bool)
signal beta_upgrades_changed(enabled: bool)

var crt_enabled: bool = true :
	set(value):
		crt_enabled = value
		crt_changed.emit(value)

var beta_upgrades_enabled: bool = false :
	set(value):
		beta_upgrades_enabled = value
		beta_upgrades_changed.emit(value)

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
	GameConstants.SkinColor.LIME
]

var unlocked_patterns: Array = [
	GameConstants.SkinPattern.SOLID,
	GameConstants.SkinPattern.STRIPE1,
	GameConstants.SkinPattern.STRIPE2,
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
