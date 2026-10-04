class_name PlateDoor
extends Node3D
## Door that is open only while its plate is pressed. Needs a WorldObject child named Panel
## (neutral, so it blocks in both 2.5D and 2D while closed).

@export_node_path("Node3D") var plate_path: NodePath
## Size of the door panel (a tall door can't be jumped over).
@export var size := Vector3(1, 4, 4)

@onready var panel: WorldObject = $Panel


func _enter_tree() -> void:
	$Panel.size = size


func _ready() -> void:
	get_node(plate_path).pressed_changed.connect(panel.set_open)
