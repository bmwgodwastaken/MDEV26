extends Node3D
## Joke main menu. Looks like a normal flat menu (2D view): Play, Credits, Quit.
## The sign says not to press Q. Pressing it switches to 2.5D, the Play button unfreezes and falls
## onto Quit, and the game closes. The buttons are real 3D slabs picked with a mouse ray.

signal landed
signal quit_requested

const LEVEL_SELECTOR := "res://Scenes/level_selector.tscn"
const QUIT_DELAY := 1.2
const BASE_COLOR := Color(0.25, 0.3, 0.4)
const HOVER_COLOR := Color(0.4, 0.5, 0.65)

## Off only for tests, so the check doesn't close the engine.
@export var really_quit := true

@onready var camera: Camera3D = $Camera3D
@onready var play: RigidBody3D = $Play
@onready var warning_sign: Label3D = $WarningSign
@onready var credits_panel: Control = $CreditsLayer/CreditsPanel

var credits_open := false
var _fallen := false
var _landed := false
var _materials := {}
var _sign_y := 0.0


## The menu always starts in the flat (2D) view, whatever the last level left behind.
func _enter_tree() -> void:
	PerspectiveManager.mode = PerspectiveManager.Mode.FLAT


func _ready() -> void:
	for slab in [$Play, $Credits, $Quit]:
		var material := StandardMaterial3D.new()
		material.albedo_color = BASE_COLOR
		slab.get_node("Mesh").material_override = material
		_materials[slab.name] = material
	_sign_y = warning_sign.position.y
	credits_panel.position.x = get_viewport().get_visible_rect().size.x # parked off-screen
	credits_panel.get_node("Box/Close").pressed.connect(_set_credits.bind(false))
	$Quit/Landing.body_entered.connect(_on_landing)
	PerspectiveManager.mode_changed.connect(_on_mode_changed)
	_apply_camera()


func _process(_delta: float) -> void:
	warning_sign.position.y = _sign_y + sin(Time.get_ticks_msec() / 400.0) * 0.15
	var hovered := _pick(get_viewport().get_mouse_position())
	for slab_name in _materials:
		_materials[slab_name].albedo_color = HOVER_COLOR if slab_name == hovered else BASE_COLOR


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_perspective"):
		PerspectiveManager.set_mode(PerspectiveManager.Mode.SOLID) # one way: no going back
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var slab := _pick(event.position)
		if slab != "":
			press(slab)


func press(slab: String) -> void:
	if _fallen and slab != "Quit":
		return
	match slab:
		"Play":
			get_tree().change_scene_to_file(LEVEL_SELECTOR)
		"Credits":
			_set_credits(not credits_open)
		"Quit":
			_quit()


## Name of the button slab under the screen position, or "".
func _pick(screen_pos: Vector2) -> String:
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	return hit.collider.name if hit and hit.collider.name in _materials else ""


func _on_mode_changed(mode: PerspectiveManager.Mode) -> void:
	_apply_camera()
	if mode != PerspectiveManager.Mode.SOLID:
		return
	_fallen = true
	warning_sign.visible = false
	_set_credits(false)
	play.freeze = false
	play.angular_velocity = Vector3(0.2, 0.0, 0.3) # a small tilt so it doesn't fall perfectly straight


## Flat side-on orthographic camera in 2D, angled perspective camera in 2.5D.
func _apply_camera() -> void:
	if PerspectiveManager.mode == PerspectiveManager.Mode.FLAT:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 9.0
		camera.position = Vector3(0, 0, 10)
		camera.rotation = Vector3.ZERO
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 55.0
		camera.look_at_from_position(Vector3(6, 3.5, 9), Vector3(0, -0.3, 0))


func _on_landing(body: Node3D) -> void:
	if body != play or _landed:
		return
	_landed = true
	landed.emit()
	await get_tree().create_timer(QUIT_DELAY).timeout
	_quit()


func _quit() -> void:
	quit_requested.emit()
	if really_quit:
		get_tree().quit()


func _set_credits(open: bool) -> void:
	credits_open = open
	var screen_width := get_viewport().get_visible_rect().size.x
	var target := screen_width - credits_panel.size.x - 24.0 if open else screen_width
	create_tween().tween_property(credits_panel, "position:x", target, 0.3).set_trans(Tween.TRANS_CUBIC)
