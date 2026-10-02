extends Node
## Autoload. Global perspective state; anything that cares listens to mode_changed.
## SOLID = 2.5D (depth), FLAT = 2D (depth ignored).

enum Mode { SOLID, FLAT }

signal mode_changed(mode: Mode)

var mode := Mode.SOLID


func set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	mode = new_mode
	mode_changed.emit(mode)
