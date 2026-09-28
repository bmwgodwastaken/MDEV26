extends GeometryInstance3D
## Put on any CSG or MeshInstance3D level piece.
## Builds its own colliders from its bounding box:
##   layer 1 (solid world) = the real box
##   layer 2 (flat world)  = the same box stretched along Z, so depth is ignored in 2D
## Faction decides which of the two it gets. Pieces missing from the current mode are ghosted.

enum Faction { NEUTRAL, SOLID, FLAT }

const SOLID_LAYER := 1
const FLAT_LAYER := 2
const FLAT_DEPTH := 1000.0
const GHOST_ALPHA := 0.2
const COLORS := {
	Faction.NEUTRAL: Color(0.6, 0.6, 0.6),
	Faction.SOLID: Color(0.25, 0.45, 1.0),
	Faction.FLAT: Color(1.0, 0.3, 0.3),
}

@export var faction := Faction.NEUTRAL

var _material := StandardMaterial3D.new()


func _ready() -> void:
	set("use_collision", false) # CSG: our colliders replace the built-in one. No-op on meshes.
	if get_aabb().size == Vector3.ZERO:
		await get_tree().process_frame # CSG builds its mesh (and AABB) one frame after _ready
	# Colliders are boxes from the bounding box, so slopes/odd shapes collide as boxes.
	var box := get_aabb()
	if faction != Faction.FLAT:
		_add_body(SOLID_LAYER, box.size, box.get_center())
	if faction != Faction.SOLID:
		_add_body(FLAT_LAYER, Vector3(box.size.x, box.size.y, FLAT_DEPTH), box.get_center())

	# Placeholder faction colors (grey / blue / red).
	_material.albedo_color = COLORS[faction]
	material_override = _material
	PerspectiveManager.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(PerspectiveManager.mode)


func exists_in(mode: PerspectiveManager.Mode) -> bool:
	return faction == Faction.NEUTRAL or (faction == Faction.SOLID) == (mode == PerspectiveManager.Mode.SOLID)


func _on_mode_changed(mode: PerspectiveManager.Mode) -> void:
	var visible_now := exists_in(mode)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if visible_now else BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = 1.0 if visible_now else GHOST_ALPHA


func _add_body(layer: int, size: Vector3, center: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(layer, true)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	shape.position = center
	body.add_child(shape)
	add_child(body)
