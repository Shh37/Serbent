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
