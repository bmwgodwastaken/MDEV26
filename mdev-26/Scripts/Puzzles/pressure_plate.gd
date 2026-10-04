class_name PressurePlate
extends Node3D
## Floor button. Pressed while a PushBox sits on it AND that box exists in the current view,
## so a box that only exists in one view stops pressing it when you switch.
## tint = the color of the box it is meant for (shown dark when released, bright when pressed).
## With pictures: a scene (Scenes/Prefabs/pressure_plate.tscn) that has "Released" and "Pressed"
## picture children shows those instead, and tint just colors them a little.

signal pressed_changed(pressed: bool)

@export var size := Vector3(2, 0.1, 2)
@export var tint := Color.WHITE

var pressed := false
var _material := StandardMaterial3D.new()
@onready var _released := get_node_or_null("Released")
@onready var _pressed_picture := get_node_or_null("Pressed")


func _ready() -> void:
	if _released and _pressed_picture:
		_released.modulate = Color.WHITE.lerp(tint, 0.6)
		_pressed_picture.modulate = _released.modulate
		_show_state()
		return
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
	_show_state()
	pressed_changed.emit(pressed)


func _show_state() -> void:
	if _released and _pressed_picture:
		_released.visible = not pressed
		_pressed_picture.visible = pressed


func _has_weight() -> bool:
	for box in get_tree().get_nodes_in_group("plate_weight"):
		if not box.exists_now():
			continue
		var offset: Vector3 = box.global_position - global_position
		if absf(offset.x) <= size.x / 2.0 and absf(offset.z) <= size.z / 2.0 and absf(offset.y) <= 1.0:
			return true
	return false
