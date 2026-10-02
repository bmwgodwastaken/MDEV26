class_name WorldObject
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
const FADE_ALPHA := 0.35
const COLORS := {
	Faction.NEUTRAL: Color(0.6, 0.6, 0.6),
	Faction.SOLID: Color(0.25, 0.45, 1.0),
	Faction.FLAT: Color(1.0, 0.3, 0.3),
}

@export var faction := Faction.NEUTRAL
## Off = stays fully visible in the mode where it has no collision (scenery, e.g. a vase in 2D).
@export var ghost := true
## Fades out while the player stands behind it in 2.5D, so the player can see what's back there.
@export var fade_when_player_behind := false

var _material := StandardMaterial3D.new()
var _player: Node3D
var _bodies: Array[StaticBody3D] = []
var _open := false


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
	_player = get_tree().get_first_node_in_group("2.5DPlayer")
	set_process(fade_when_player_behind)
	PerspectiveManager.mode_changed.connect(_refresh.unbind(1))
	_refresh()
	_apply_open()


## Open = hidden and no collision in either mode (e.g. a door). Safe to call before _ready finishes.
func set_open(value: bool) -> void:
	_open = value
	_apply_open()


func _apply_open() -> void:
	visible = not _open
	for body in _bodies:
		body.collision_layer = 0 if _open else 1 << (body.get_meta("layer") - 1)


static func exists_in_mode(piece_faction: Faction, mode: PerspectiveManager.Mode) -> bool:
	return piece_faction == Faction.NEUTRAL or (piece_faction == Faction.SOLID) == (mode == PerspectiveManager.Mode.SOLID)


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var alpha := 1.0
	if ghost and not exists_in_mode(faction, PerspectiveManager.mode):
		alpha = GHOST_ALPHA
	elif fade_when_player_behind and _player_behind():
		alpha = FADE_ALPHA
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if alpha == 1.0 else BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = alpha


## "Behind" = further from the camera (smaller Z) and roughly lined up in X.
func _player_behind() -> bool:
	if PerspectiveManager.mode != PerspectiveManager.Mode.SOLID:
		return false
	var box := global_transform * get_aabb()
	var p := _player.global_position
	return p.z < box.position.z and p.x > box.position.x - 1.0 and p.x < box.end.x + 1.0


func _add_body(layer: int, size: Vector3, center: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(layer, true)
	body.set_meta("layer", layer)
	_bodies.append(body)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	shape.position = center
	body.add_child(shape)
	add_child(body)
