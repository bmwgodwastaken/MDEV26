extends Node
## Child of the player. Press switch_perspective to flip SOLID (2.5D) <-> FLAT (2D).
## Controller-agnostic: only touches the body's collision mask, Z lock and Z position.

const SOLID_LAYER := 1
const FLAT_LAYER := 2
const FALL_LIMIT := -20.0

@onready var body: CharacterBody3D = get_parent()
@onready var _shape_node: CollisionShape3D = body.find_children("*", "CollisionShape3D", false)[0]
var _probe: Shape3D


func _ready() -> void:
	# Slightly shrunk copy of the player shape, so just touching the floor/walls isn't "blocked".
	_probe = _shape_node.shape.duplicate()
	if _probe is CapsuleShape3D:
		_probe.radius *= 0.9
		_probe.height *= 0.9
	PerspectiveManager.mode_changed.connect(_apply)
	_apply(PerspectiveManager.mode)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_perspective"):
		toggle()


func _physics_process(_delta: float) -> void:
	# Fell off the level: reset to 2.5D and reload the scene.
	if body.global_position.y < FALL_LIMIT:
		PerspectiveManager.mode = PerspectiveManager.Mode.SOLID
		get_tree().reload_current_scene()


## Returns false if the switch was refused.
func toggle() -> bool:
	var solid := PerspectiveManager.Mode.SOLID
	var target := PerspectiveManager.Mode.FLAT if PerspectiveManager.mode == solid else solid
	var z := body.global_position.z
	if target == solid:
		z = _floor_depth(z)
	if _blocked(target, z):
		return false # would end up inside geometry
	body.global_position.z = z
	PerspectiveManager.set_mode(target)
	return true


func _apply(mode: PerspectiveManager.Mode) -> void:
	var flat := mode == PerspectiveManager.Mode.FLAT
	body.set_collision_mask_value(SOLID_LAYER, not flat)
	body.set_collision_mask_value(FLAT_LAYER, flat)
	body.axis_lock_linear_z = flat
	body.velocity.z = 0.0


## Going back to 2.5D: move onto the real depth of whatever we're standing on in 2D.
func _floor_depth(z: float) -> float:
	var from := body.global_position
	var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 1.5)
	ray.collision_mask = 1 << (FLAT_LAYER - 1)
	ray.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(ray)
	var piece := (hit.collider.get_parent() as GeometryInstance3D) if hit else null
	if not piece:
		return z
	var box := piece.global_transform * piece.get_aabb()
	var margin := minf(0.5, box.size.z / 2.0)
	return clampf(z, box.position.z + margin, box.end.z - margin)


func _blocked(mode: PerspectiveManager.Mode, z: float) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _probe
	query.transform = _shape_node.global_transform
	query.transform.origin.z = z
	query.collision_mask = 1 << ((FLAT_LAYER if mode == PerspectiveManager.Mode.FLAT else SOLID_LAYER) - 1)
	query.exclude = [body.get_rid()]
	return not body.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
