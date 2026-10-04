@tool
extends Node3D
## The lab wall behind a level: a plain wall that repeats, with the decorated band along the top.
## Centered on this node, facing +Z, `size` meters wide and tall. Pictures only, no collision.
## @tool: shows in the editor too, and follows `size` when you change it.

const PX_PER_M := 25.0 # the artist's scale
const BAND := preload("res://Assets/Art/background_band.png")
const WALL := preload("res://Assets/Art/background_wall.png")

@export var size := Vector2(60, 8):
	set(value):
		size = value
		if is_node_ready():
			_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for picture in get_children():
		picture.queue_free() # they are drawn by this script, never saved in the scene
	var band_height := BAND.get_height() / PX_PER_M
	var wall_height := size.y - band_height
	var tile := Vector2(WALL.get_size()) / PX_PER_M # one wall tile in meters
	_add_picture(WALL, Vector2(size.x, wall_height), Vector3(0, -size.y / 2.0 + wall_height / 2.0, 0), Vector2(size.x / tile.x, wall_height / tile.y))
	_add_picture(BAND, Vector2(size.x, band_height), Vector3(0, size.y / 2.0 - band_height / 2.0, 0), Vector2(size.x / tile.x, 1.0))


func _add_picture(texture: Texture2D, picture_size: Vector2, at: Vector3, repeats: Vector2) -> void:
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = picture_size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = texture
	material.uv1_scale = Vector3(repeats.x, repeats.y, 1.0)
	var quad := MeshInstance3D.new()
	quad.mesh = quad_mesh
	quad.material_override = material
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = at
	add_child(quad)
