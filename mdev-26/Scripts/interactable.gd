class_name Interactable
extends Node3D
## Base for anything the player can press E on (keys, doors, later levers/planks).
## The player's Interactor picks the nearest one that exists in the current mode,
## is in range, and has a clear line of sight from the player.

@export var faction := WorldObject.Faction.NEUTRAL
@export var interact_range := 1.5
## How high above this node the floating prompt sits.
@export var prompt_height := 1.0


func _ready() -> void:
	add_to_group("interactable")
	PerspectiveManager.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(PerspectiveManager.mode)


func exists_now() -> bool:
	return WorldObject.exists_in_mode(faction, PerspectiveManager.mode)


## Text for the floating prompt.
func get_prompt() -> String:
	return ""


func interact() -> void:
	pass


## Colliders that belong to this interactable, so they don't block its own line of sight.
func sight_exclude() -> Array[RID]:
	return []


## Hidden completely in the other mode (no ghost), so hidden items stay hidden.
func _on_mode_changed(_mode: PerspectiveManager.Mode) -> void:
	visible = exists_now()


## Colored box stand-in until real art is added as a child.
func _add_placeholder(size: Vector3, color: Color) -> void:
	if get_child_count() > 0:
		return
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	add_child(mesh)
