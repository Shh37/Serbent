extends Node

signal crt_changed(enabled: bool)

var crt_enabled: bool = true :
	set(value):
		crt_enabled = value
		crt_changed.emit(value)
