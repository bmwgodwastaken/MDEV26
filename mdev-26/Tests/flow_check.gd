extends SceneTree
## Headless check of the level flow: exit -> Level Complete screen -> Next Level. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/flow_check.gd

const LEVELS := [
	"res://Scenes/Levels/level_01_tutorial.tscn",
	"res://Scenes/Levels/level_02_vanishing_box.tscn",
	"res://Scenes/Levels/level_03_plank_bridge.tscn",
]


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _open(path: String) -> Node:
	if current_scene:
		current_scene.free()
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	return scene


## Teleport the player onto the exit and wait (up to 10 s) for the transition to hand over to the Level Complete screen.
func _finish_level() -> void:
	var goal = current_scene.get_node("Goal")
	var player = current_scene.get_node("2_5DCharacter")
	player.global_position = goal.global_position
	player.velocity = Vector3.ZERO
	for i in 600:
		await physics_frame
		if current_scene and current_scene.name == "LevelComplete":
			return


func _run() -> void:
	_open(LEVELS[0])
	await _frames(20)

	# The transition: the player stops, the camera zooms in on the flag, then the screen zooms out.
	var player = current_scene.get_node("2_5DCharacter")
	var camera: Camera3D = current_scene.get_node("CameraController2_5D")
	var start_fov := camera.fov
	player.global_position = current_scene.get_node("Goal").global_position
	await _frames(10) # reached the exit; the player is told to stop
	assert(not player.controls_enabled, "the player is frozen at the exit")
	var x_when_frozen: float = player.global_position.x
	Input.action_press("right")
	await _frames(30)
	Input.action_release("right")
	assert(is_equal_approx(player.global_position.x, x_when_frozen), "frozen player must not walk, moved %s" % (player.global_position.x - x_when_frozen))
	var zoomed_in := false
	for i in 600:
		await physics_frame
		if current_scene and current_scene.name == "LevelComplete":
			break
		if is_instance_valid(camera) and camera.fov < start_fov - 10.0:
			zoomed_in = true
	assert(zoomed_in, "the camera should zoom in on the flag before the screen opens")
	assert(current_scene.name == "LevelComplete", "exit should open the Level Complete screen, got %s" % current_scene.name)
	assert(current_scene.scale.x > 1.5, "the screen starts zoomed in, scale %s" % current_scene.scale.x)
	await create_timer(1.6).timeout
	assert(is_equal_approx(current_scene.scale.x, 1.0) and is_equal_approx(current_scene.modulate.a, 1.0), "the screen settles to normal size")
	assert(not LevelFlow.play_intro, "the intro only plays once")

	# Level 1 exit -> Level Complete, with a Next Level button that opens level 2.
	_open(LEVELS[0])
	await _frames(20)
	await _finish_level()
	assert(current_scene.name == "LevelComplete", "exit should open the Level Complete screen, got %s" % current_scene.name)
	var next_button: Button = current_scene.get_node("Button2")
	assert(next_button.visible, "Next Level should be offered after level 1")
	next_button.pressed.emit()
	await _frames(20)
	assert(current_scene.name == "Level02VanishingBox", "Next Level should open level 2, got %s" % current_scene.name)
	assert(LevelFlow.next_level == "", "a freshly loaded level clears the next-level memory")

	# Level 2 exit -> Level Complete -> Next Level opens level 3.
	await _finish_level()
	assert(current_scene.name == "LevelComplete", "level 2 exit should open the Level Complete screen")
	current_scene.get_node("Button2").pressed.emit()
	await _frames(20)
	assert(current_scene.name == "Level03PlankBridge", "Next Level should open level 3, got %s" % current_scene.name)

	# Last level: the screen has no Next Level button, and Main Menu works.
	await _finish_level()
	assert(current_scene.name == "LevelComplete", "level 3 exit should open the Level Complete screen")
	assert(not current_scene.get_node("Button2").visible, "no Next Level after the last level")
	current_scene.get_node("Button").button_down.emit()
	await _frames(20)
	assert(current_scene.name == "MainMenu", "Main Menu button should open the main menu, got %s" % current_scene.name)

	print("flow_check: ALL PASSED")
	quit(0)
