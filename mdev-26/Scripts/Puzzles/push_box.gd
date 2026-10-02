class_name PushBox
extends CharacterBody3D
## A box the player pushes by walking into it (see pusher.gd). It only exists in one view:
##   SOLID = 2.5D only (real box, layer 1)   FLAT = 2D only (box stretched along Z, layer 2)
## In the other view it is a faint ghost with no collision and frozen in place, so its
## position is remembered when you switch back. Boxes press PressurePlates via the group below.

const FLAT_DEPTH := 1000.0
const FALL_LIMIT := -20.0
const GHOST_ALPHA := 0.2

@export var faction := WorldObject.Faction.SOLID
@export var size := Vector3.ONE

var _start: Vector3
var _shape := CollisionShape3D.new()
var _material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("plate_weight")
	_start = global_position
	var flat := faction == WorldObject.Faction.FLAT
	_shape.shape = BoxShape3D.new()
	_shape.shape.size = Vector3(size.x, size.y, FLAT_DEPTH) if flat else size
	add_child(_shape)
	axis_lock_linear_z = flat # a 2D box only slides along X
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	_material.albedo_color = WorldObject.COLORS[faction]
	mesh.material_override = _material
	add_child(mesh)
	PerspectiveManager.mode_changed.connect(_refresh.unbind(1))
	_refresh()


func exists_now() -> bool:
	return WorldObject.exists_in_mode(faction, PerspectiveManager.mode)


## Called by the player's Pusher with a small horizontal motion.
func push(motion: Vector3) -> void:
	if exists_now():
		move_and_collide(motion)


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()
	# Pushed into the pit: back to where it started so the puzzle can't be lost.
	if global_position.y < FALL_LIMIT:
		global_position = _start
		velocity = Vector3.ZERO


## Collides only in its own view; in the other view it is a frozen ghost.
func _refresh() -> void:
	var here := exists_now()
	collision_layer = 0
	collision_mask = 0
	if here:
		var layer := WorldObject.FLAT_LAYER if faction == WorldObject.Faction.FLAT else WorldObject.SOLID_LAYER
		set_collision_layer_value(layer, true)
		set_collision_mask_value(layer, true)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if here else BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = 1.0 if here else GHOST_ALPHA
	set_physics_process(here)
