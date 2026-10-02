extends Camera3D

## 2D camera: orthographic, straight side-on at this height.
@export var flat_height := 2.0
@export var flat_size := 14.0

var player:CharacterBody3D
@onready var _solid_pose := transform

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("2.5DPlayer")
	PerspectiveManager.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(PerspectiveManager.mode)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.x = player.global_position.x

# Instant cut between the saved 2.5D pose and a flat side-on orthographic view.
func _on_mode_changed(mode: PerspectiveManager.Mode) -> void:
	transform = _solid_pose
	projection = PROJECTION_PERSPECTIVE
	if mode == PerspectiveManager.Mode.FLAT:
		projection = PROJECTION_ORTHOGONAL
		size = flat_size
		rotation = Vector3.ZERO
		position.y = flat_height
