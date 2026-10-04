@tool
class_name ViewSprite3D
extends Sprite3D
## A picture that is different in 2.5D and in 2D (e.g. the flag). It stands on the floor in both:
## the bottom edge of whichever picture is showing sits at ground_y.
## @tool: the editor shows the 2.5D picture standing on the floor.
## lie_flat_in_25d: for things drawn from above in 2.5D (a key, a plate) and from the side in 2D:
## the picture lies flat on the floor in 2.5D and stands up in 2D.

@export var texture_25d: Texture2D
@export var texture_2d: Texture2D
## Local height of the floor under this sprite.
@export var ground_y := 0.0
@export var lie_flat_in_25d := false

const FLAT_LIFT := 0.02 # a flat picture floats just above the floor so it doesn't flicker


func _ready() -> void:
	if not Engine.is_editor_hint():
		PerspectiveManager.mode_changed.connect(_apply.unbind(1))
	_apply()


func _apply() -> void:
	var flat := not Engine.is_editor_hint() and PerspectiveManager.mode == PerspectiveManager.Mode.FLAT
	var picture := texture_2d if flat else texture_25d
	if picture == null:
		return
	texture = picture
	if lie_flat_in_25d and not flat:
		axis = Vector3.AXIS_Y
		position.y = ground_y + FLAT_LIFT
	else:
		axis = Vector3.AXIS_Z
		position.y = ground_y + picture.get_height() * pixel_size / 2.0
