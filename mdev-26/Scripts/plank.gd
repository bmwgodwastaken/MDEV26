extends RigidBody3D

var Plank_Spwaner:PlankSpwaner

func  _ready() -> void:
	Plank_Spwaner = get_tree().current_scene.get_node_or_null("PlankSpwaner")

func _process(delta: float) -> void:
	if global_position.y <= -20:
		if Plank_Spwaner:
			Plank_Spwaner.last_spwan_planks.erase(self)
			queue_free()
		#global_position = spwan_position
		#global_rotation = spwan_rotation
