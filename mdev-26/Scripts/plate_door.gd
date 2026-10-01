class_name PlateDoor
extends Node3D
## Door that is open only while its plate is pressed. Needs a WorldObject child named Panel
## (neutral, so it blocks in both 2.5D and 2D while closed).

@export_node_path("Node3D") var plate_path: NodePath

@onready var panel: WorldObject = $Panel


func _ready() -> void:
	get_node(plate_path).pressed_changed.connect(panel.set_open)
