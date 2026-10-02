extends Node
## Child of the player. Each frame finds the nearest Interactable that exists in the
## current mode, is in range, and that the player can see; shows its floating prompt
## and sends the interact press (E) to it.
## In 2D, range ignores depth (Z), like everything else in 2D.

const SOLID_LAYER := 1
const FLAT_LAYER := 2

@onready var body: CharacterBody3D = get_parent()
var _target: Interactable
var _prompt := Label.new()


func _ready() -> void:
	var layer := CanvasLayer.new()
	_prompt.add_theme_font_size_override("font_size", 24)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.visible = false
	layer.add_child(_prompt)
	add_child(layer)


func _process(_delta: float) -> void:
	_target = find_target()
	_prompt.visible = _target != null
	if not _target:
		return
	_prompt.text = _target.get_prompt()
	_prompt.reset_size()
	var camera := get_viewport().get_camera_3d()
	var above := _target.global_position + Vector3.UP * _target.prompt_height
	_prompt.position = camera.unproject_position(above) - _prompt.size / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _target:
		_target.interact()


func find_target() -> Interactable:
	var flat := PerspectiveManager.mode == PerspectiveManager.Mode.FLAT
	var best: Interactable
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		var item := node as Interactable
		if not item.exists_now():
			continue
		var offset := item.global_position - body.global_position
		if flat:
			offset.z = 0.0
		var distance := offset.length()
		if distance <= item.interact_range and distance < best_distance and _can_see(item, flat):
			best = item
			best_distance = distance
	return best


## Line of sight from the player to the item, against the current mode's world.
func _can_see(item: Interactable, flat: bool) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(body.global_position, item.global_position)
	ray.collision_mask = 1 << ((FLAT_LAYER if flat else SOLID_LAYER) - 1)
	ray.exclude = [body.get_rid()] + item.sight_exclude()
	return body.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
