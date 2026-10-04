class_name KeyDoor
extends Node3D
## A door that needs a key. Use it through Scenes/Prefabs/locked_door.tscn: drop the scene in,
## set key_id (and size if needed). Put the origin at the middle of the door.
## Panel = the solid door piece (both views), Lock = what you press E on.

@export var key_id := "red"
@export var size := Vector3(1, 4, 4)


func _enter_tree() -> void:
	$Panel.size = size
	$Lock.key_id = key_id
	$Lock.position.y = -size.y / 2.0 + 1.0 # one meter above the floor
