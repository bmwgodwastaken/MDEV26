class_name Goal
extends Node3D
## Level exit. Reached when the player is within `radius`; in 2D depth (Z) is ignored,
## like everything else in 2D. Then: the player stops, the camera zooms into the flag until it
## fills the screen (fading to black), and the Level Complete screen zooms out from there.
## That screen's "Next Level" button opens next_scene (no button if it is empty).

signal reached

const LEVEL_COMPLETE := "res://Scenes/level_complete.tscn"
const ZOOM_FOV := 40.0 # 2.5D camera ends up this narrow, 1.3 m from the flag
const ZOOM_DISTANCE := 1.3
const ZOOM_ORTHO_SIZE := 1.2 # 2D camera ends up showing this many meters of height
const FADE_FROM := 0.7 # the black fade starts this far into the zoom (0..1)

@export var radius := 1.5
## The level the Level Complete screen offers next ("" = none, e.g. the last level).
@export_file("*.tscn") var next_scene := ""
## The screen shown when the level is finished. Empty = no screen (checks use this to stay in the level).
@export_file("*.tscn") var complete_scene := LEVEL_COMPLETE
## Seconds the player gets to come to a stop (and land) before the camera starts to move.
@export var freeze_time := 0.4
@export var zoom_time := 1.3

var _done := false
var _camera: Camera3D
var _fade: ColorRect
var _target := Vector3.ZERO
var _start_position := Vector3.ZERO
var _start_rotation := Quaternion.IDENTITY
var _end_position := Vector3.ZERO
var _end_rotation := Quaternion.IDENTITY
var _start_fov := 75.0
var _start_size := 14.0


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("2.5DPlayer")
	if _done or not player:
		return
	var offset: Vector3 = player.global_position - global_position
	if PerspectiveManager.mode == PerspectiveManager.Mode.FLAT:
		offset.z = 0.0
	if offset.length() > radius:
		return
	_done = true
	reached.emit()
	Audio.play("level_success_sfx")
	if complete_scene != "":
		LevelFlow.next_level = next_scene
		TimeManager.stop_timer()
		_play_transition(player)
	elif next_scene != "":
		get_tree().change_scene_to_file.call_deferred(next_scene)
	else:
		_show_message("Level complete!")


## Player stops -> zoom into the flag -> Level Complete screen (which zooms back out).
func _play_transition(player: Node) -> void:
	player.controls_enabled = false # walking, jumping, grabbing; gravity still lands a jump
	for child in player.get_children():
		child.set_process_unhandled_input(false) # no view switch or interact while it plays
	await get_tree().create_timer(freeze_time).timeout

	_camera = get_viewport().get_camera_3d()
	_camera.set_process(false) # the camera script would keep following the player
	var flag := get_node_or_null("Flag") as Node3D
	_target = flag.global_position if flag else global_position
	_start_position = _camera.global_position
	_start_rotation = _camera.global_basis.get_rotation_quaternion()
	_start_fov = _camera.fov
	_start_size = _camera.size
	_end_position = _target + Vector3(0, 0.2, ZOOM_DISTANCE)
	_end_rotation = Basis.looking_at(_target - _end_position).get_rotation_quaternion()

	var layer := CanvasLayer.new()
	layer.layer = 100
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	add_child(layer)

	var zoom := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	zoom.tween_method(_zoom_step, 0.0, 1.0, zoom_time)
	await zoom.finished
	LevelFlow.play_intro = true
	get_tree().change_scene_to_file(complete_scene)


## t = 0 is the normal view, t = 1 is the flag filling the screen (and black).
func _zoom_step(t: float) -> void:
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_camera.size = lerpf(_start_size, ZOOM_ORTHO_SIZE, t)
		_camera.global_position = _start_position.lerp(Vector3(_target.x, _target.y, _start_position.z), t)
	else:
		_camera.global_position = _start_position.lerp(_end_position, t)
		_camera.global_basis = Basis(_start_rotation.slerp(_end_rotation, t))
		_camera.fov = lerpf(_start_fov, ZOOM_FOV, t)
	_fade.color.a = clampf((t - FADE_FROM) / (1.0 - FADE_FROM), 0.0, 1.0)


func _show_message(text: String) -> void:
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	layer.add_child(label)
	add_child(layer)
