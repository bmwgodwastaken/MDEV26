@tool
class_name WorldObject
extends GeometryInstance3D
## Put on any CSG or MeshInstance3D level piece.
## Builds its own colliders from its bounding box:
##   layer 1 (solid world) = the real box
##   layer 2 (flat world)  = the same box stretched along Z, so depth is ignored in 2D
## Faction decides which of the two it gets. Pieces missing from the current mode are ghosted.
## `art` dresses the piece with the artist's pictures instead of the plain placeholder color.
## @tool: in the editor it only draws those pictures as a preview (they are not saved with the scene).

enum Faction { NEUTRAL, SOLID, FLAT }
## FLOOR = stone block: 2.5D tile on top, 2D tile on the front.  DOOR = a door picture on the front.
enum Art { NONE, FLOOR, DOOR }

const PX_PER_M := 25.0 # the artist's scale: the 2 m tall player is about 49 px
const ART_OFFSET := 0.01 # picture sits just in front of the box so they don't flicker
const UNDERLAY := Color(0.24, 0.23, 0.33) # color of the box under the pictures
const ART_TINT := {
	Faction.NEUTRAL: Color(1, 1, 1),
	Faction.SOLID: Color(0.55, 0.7, 1.0),
	Faction.FLAT: Color(1.0, 0.55, 0.55),
}
const FLOOR_25D := preload("res://Assets/Art/floor_25d.png")
const FLOOR_2D := preload("res://Assets/Art/floor_2d.png")
const DOOR := preload("res://Assets/Art/door.png")

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
@export var art := Art.NONE
## Off = the box itself is invisible and a Sprite3D child stands in for it (e.g. the vase).
## The sprite fades and ghosts together with the piece.
@export var show_box := true

var _art_materials: Array[StandardMaterial3D] = []
var _sprites: Array[Node] = []
var _art_pictures: Array[MeshInstance3D] = []
var _preview_key := [] # what the editor preview was last built for
var _material := StandardMaterial3D.new()
var _player: Node3D
var _bodies: Array[StaticBody3D] = []
var _open := false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true) # keeps the editor preview up to date when you resize or change the piece
		return
	set("use_collision", false) # CSG: our colliders replace the built-in one. No-op on meshes.
	if get_aabb().size == Vector3.ZERO:
		await get_tree().process_frame # CSG builds its mesh (and AABB) one frame after _ready
	# Colliders are boxes from the bounding box, so slopes/odd shapes collide as boxes.
	var box := get_aabb()
	if faction != Faction.FLAT:
		_add_body(SOLID_LAYER, box.size, box.get_center())
	if faction != Faction.SOLID:
		_add_body(FLAT_LAYER, Vector3(box.size.x, box.size.y, FLAT_DEPTH), box.get_center())

	# Placeholder faction colors (grey / blue / red), or a dark box under the artist's pictures.
	_material.albedo_color = COLORS[faction] if art == Art.NONE else UNDERLAY
	material_override = _material
	_sprites = find_children("*", "Sprite3D", false, false)
	if not show_box:
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_art(box)
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
	if Engine.is_editor_hint():
		_update_editor_preview()
		return
	_refresh()


## Editor only: (re)draw the pictures whenever the box, the art or the faction changes.
func _update_editor_preview() -> void:
	var box := get_aabb()
	var key := [box, art, faction]
	if key == _preview_key:
		return
	_preview_key = key
	_clear_art()
	if box.size != Vector3.ZERO:
		_build_art(box)


func _clear_art() -> void:
	for picture in _art_pictures:
		picture.queue_free()
	_art_pictures.clear()
	_art_materials.clear()


func _refresh() -> void:
	var alpha := 1.0
	if ghost and not exists_in_mode(faction, PerspectiveManager.mode):
		alpha = GHOST_ALPHA
	elif fade_when_player_behind and _player_behind():
		alpha = FADE_ALPHA
	var transparency := BaseMaterial3D.TRANSPARENCY_DISABLED if alpha == 1.0 else BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.transparency = transparency if show_box else BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = alpha if show_box else 0.0
	for sprite in _sprites:
		sprite.modulate.a = alpha
	for art_material in _art_materials:
		art_material.transparency = transparency
		art_material.albedo_color = Color(ART_TINT[faction], alpha) # faction tint, same ghosting as the box


func _build_art(box: AABB) -> void:
	var center := box.get_center()
	match art:
		Art.FLOOR:
			var tile := Vector2(FLOOR_25D.get_size()) / PX_PER_M # one tile in meters
			_add_picture(FLOOR_25D, Vector2(box.size.x, box.size.z), Vector3(center.x, box.end.y + ART_OFFSET, center.z), -PI / 2.0, Vector2(box.size.x / tile.x, box.size.z / tile.y))
			_add_picture(FLOOR_2D, Vector2(box.size.x, box.size.y), Vector3(center.x, center.y, box.end.z + ART_OFFSET), 0.0, Vector2(box.size.x / tile.x, 1.0))
		Art.DOOR:
			var door_size := Vector2(DOOR.get_size()) / PX_PER_M
			_add_picture(DOOR, door_size, Vector3(center.x, box.position.y + door_size.y / 2.0, box.end.z + ART_OFFSET), 0.0, Vector2.ONE)


## A flat picture (unlit, crisp pixels) repeated `repeats` times across `size`; pitch -90 degrees lays it flat.
func _add_picture(texture: Texture2D, size: Vector2, at: Vector3, pitch: float, repeats: Vector2) -> void:
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = size
	var picture_material := StandardMaterial3D.new()
	picture_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	picture_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	picture_material.albedo_texture = texture
	picture_material.albedo_color = Color(ART_TINT[faction], 1.0)
	picture_material.uv1_scale = Vector3(repeats.x, repeats.y, 1.0)
	var quad := MeshInstance3D.new()
	quad.mesh = quad_mesh
	quad.material_override = picture_material
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = at
	quad.rotation.x = pitch
	add_child(quad)
	_art_materials.append(picture_material)
	_art_pictures.append(quad)


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
