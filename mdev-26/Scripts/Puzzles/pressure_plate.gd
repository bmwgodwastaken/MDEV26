class_name PressurePlate
extends Node3D
## Floor button. Pressed while a PushBox sits on it AND that box exists in the current view,
## so a box that only exists in one view stops pressing it when you switch.
## tint = the color of the box it is meant for (shown dark when released, bright when pressed).

signal pressed_changed(pressed: bool)

@export var size := Vector3(2, 0.1, 2)
@export var tint := Color.WHITE

var pressed := false
var _material := StandardMaterial3D.new()


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.material_override = _material
	add_child(mesh)
	_material.albedo_color = tint.darkened(0.5)


func _physics_process(_delta: float) -> void:
	var now := _has_weight()
	if now == pressed:
		return
	pressed = now
	_material.albedo_color = tint if pressed else tint.darkened(0.5)
	pressed_changed.emit(pressed)


func _has_weight() -> bool:
	for box in get_tree().get_nodes_in_group("plate_weight"):
		if not box.exists_now():
			continue
		var offset: Vector3 = box.global_position - global_position
		if absf(offset.x) <= size.x / 2.0 and absf(offset.z) <= size.z / 2.0 and absf(offset.y) <= 1.0:
			return true
	return false
