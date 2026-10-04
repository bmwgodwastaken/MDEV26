extends Label



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if TimeManager.is_timing:
		text = str(round(TimeManager.current_time * 1000) / 1000)
