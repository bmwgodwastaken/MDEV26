class_name KeyPickup
extends Interactable
## A key the player picks up with E. Defaults to existing only in 2.5D;
## set faction to FLAT for a key that only exists in 2D (e.g. inside a painting).

signal picked_up(key_id: String)

@export var key_id := "red"
## On = the key's picture stays invisible until the player can actually see it: close enough and
## nothing in the way. A key hidden behind a vase is then not visible at all from the front.
@export var reveal_by_sight := false
@export var reveal_range := 3.0
@export var reveal_time := 0.25

var _revealed := 0.0


func _init() -> void:
	faction = WorldObject.Faction.SOLID


func _ready() -> void:
	super()
	# The key picture is grey, so any key_id color works: tint it. No picture = colored box.
	var pictures := find_children("*", "Sprite3D", true, false)
	for picture in pictures:
		picture.modulate = Color.from_string(key_id, Color.WHITE)
	if pictures.is_empty():
		_add_placeholder(Vector3(0.3, 0.3, 0.3), Color.from_string(key_id, Color.WHITE))
	set_process(reveal_by_sight)
	_set_picture_alpha(0.0 if reveal_by_sight else 1.0)


func _process(delta: float) -> void:
	var target := 1.0 if _can_be_seen() else 0.0
	_revealed = move_toward(_revealed, target, delta / reveal_time)
	_set_picture_alpha(_revealed)


func _set_picture_alpha(alpha: float) -> void:
	for picture in find_children("*", "Sprite3D", true, false):
		picture.modulate.a = alpha


## Same rules as the interact prompt: right view, within range, nothing solid in between.
func _can_be_seen() -> bool:
	var player := get_tree().get_first_node_in_group("2.5DPlayer") as CharacterBody3D
	if not player or not exists_now():
		return false
	var flat := PerspectiveManager.mode == PerspectiveManager.Mode.FLAT
	var offset := global_position - player.global_position
	if flat:
		offset.z = 0.0
	if offset.length() > reveal_range:
		return false
	var ray := PhysicsRayQueryParameters3D.create(player.global_position, global_position)
	ray.collision_mask = 1 << ((WorldObject.FLAT_LAYER if flat else WorldObject.SOLID_LAYER) - 1)
	ray.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func get_prompt() -> String:
	return "E  Pick up %s key" % key_id


func interact() -> void:
	Inventory.add_key(key_id)
	picked_up.emit(key_id)
	remove_from_group("interactable")
	queue_free()
