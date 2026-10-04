extends Label



func _ready() -> void:
	text = "Time Completed: " + str(round(TimeManager.current_time * 1000) / 1000)
