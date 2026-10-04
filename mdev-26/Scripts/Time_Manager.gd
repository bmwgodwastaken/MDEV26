extends Node

var current_time = 0.0
var is_timing = false


func  _ready() -> void:
	pass

func start_timer():
	if not is_timing:
		current_time = 0.0
		is_timing = true
	else:
		printerr("Timer Already Started")

func stop_timer():
	if is_timing:
		is_timing = false
	else:
		printerr("Timer Already Stoped")

func _process(delta: float) -> void:
	if is_timing:
		current_time += 1 * delta
		#print(current_time)
