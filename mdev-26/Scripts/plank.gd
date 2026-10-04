class_name GrabPlank
extends RigidBody3D
## A plank the player can grab (G). Two colliders, like level pieces:
##   the plank itself (layer 1)   = the real plank, for 2.5D
##   FlatBody child   (layer 2)   = the same plank stretched along Z, so it holds you in 2D too
## Planks keep flat (no tipping or spinning). One that falls out of the world is deleted
## and its spawner makes a new one.

## Set by the spawner that made this plank (or found by name for hand-placed planks).
var Plank_Spwaner: PlankSpwaner

func _ready() -> void:
	if Plank_Spwaner == null:
		Plank_Spwaner = get_parent().get_node_or_null("PlankSpwaner")

func _process(_delta: float) -> void:
	if global_position.y <= -20:
		if Plank_Spwaner:
			Plank_Spwaner.last_spwan_planks.erase(self)
		queue_free()
