class_name Goal
extends Node3D
## Level exit. Reached when the player is within `radius`; in 2D depth (Z) is ignored,
## like everything else in 2D. Loads next_scene, or shows "Level complete!" if it is empty.

signal reached

@export var radius := 1.5
@export_file("*.tscn") var next_scene := ""

var _done := false


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("2.5DPlayer")
	if _done or not player:
		return
	var offset: Vector3 = player.global_position - global_position
	if PerspectiveManager.mode == PerspectiveManager.Mode.FLAT:
		offset.z = 0.0
	if offset.length() > radius:
		return
	_done = true
	reached.emit()
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
	else:
		_show_message("Level complete!")


func _show_message(text: String) -> void:
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	layer.add_child(label)
	add_child(layer)
