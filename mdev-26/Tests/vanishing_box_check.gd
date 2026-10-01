extends SceneTree
## Headless check for the pushable vanishing boxes + plates + doors. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/vanishing_box_check.gd

var player: CharacterBody3D
var switcher: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = load("res://Scenes/vanishing_box_test.tscn").instantiate()
	root.add_child(level)
	player = level.get_node("2_5DCharacter")
	switcher = player.get_node("PerspectiveSwitcher")
	var blue_box = level.get_node("BlueBox")
	var red_box = level.get_node("RedBox")
	var plate_blue = level.get_node("PlateBlue")
	var plate_red = level.get_node("PlateRed")
	var door_blue = level.get_node("DoorBlue/Panel")
	var door_red = level.get_node("DoorRed/Panel")

	# 1. Start: nothing on a plate, both doors closed.
	await _frames(20)
	assert(not plate_blue.pressed and door_blue.visible, "blue door starts closed")
	assert(not plate_red.pressed and door_red.visible, "red door starts closed")

	# 2. 2.5D: push the blue box along the lane, past the pillar, onto the blue plate.
	await _place(Vector3(2.5, 1.1, 1.2))
	Input.action_press("right")
	await _frames(260)
	Input.action_release("right")
	assert(blue_box.global_position.x > 10.5, "blue box should be pushed to the plate, x=%s" % blue_box.global_position.x)
	assert(plate_blue.pressed and not door_blue.visible, "blue plate should be pressed and blue door open in 2.5D")

	# 3. Switch to 2D: the blue box vanishes, the plate releases, the door closes.
	assert(switcher.toggle(), "switch to 2D")
	await _frames(5)
	assert(not plate_blue.pressed and door_blue.visible, "blue door should close in 2D")

	# 4. Cross the gap in 2D (hop over the stopper), switch back on the far side: door reopens.
	await _place(Vector3(14, 1.1, 1.2))
	await _place(Vector3(18, 1.1, 1.2))
	assert(switcher.toggle(), "switch to 2.5D on far platform")
	assert(player.global_position.z < -10.0, "should snap onto the far lane, z=%s" % player.global_position.z)
	await _frames(5)
	assert(plate_blue.pressed and not door_blue.visible, "blue door should reopen in 2.5D")
	Input.action_press("right")
	await _frames(70)
	Input.action_release("right")
	assert(player.global_position.x > 21.0, "should walk through the open blue door, x=%s" % player.global_position.x)

	# 5. Past the door, the red box is only a ghost in 2.5D and the red door is shut.
	await _place(Vector3(22.5, 1.1, -10.5))
	assert(not red_box.exists_now() and door_red.visible, "red box should not exist in 2.5D")

	# 6. Switch to 2D and push the red box onto the red plate: red door opens.
	assert(switcher.toggle(), "switch to 2D near red box")
	Input.action_press("right")
	await _frames(260)
	Input.action_release("right")
	assert(red_box.global_position.x > 28.9, "red box should be pushed to the plate, x=%s" % red_box.global_position.x)
	assert(plate_red.pressed and not door_red.visible, "red plate pressed and red door open in 2D")

	# 7. Back in 2.5D the red box vanishes and the red door closes again.
	assert(switcher.toggle(), "switch back to 2.5D")
	await _frames(5)
	assert(not plate_red.pressed and door_red.visible, "red door should close in 2.5D")

	# 8. A box pushed into the pit resets to its start.
	blue_box.global_position = Vector3(11, -25, 1)
	await _frames(5)
	assert(blue_box.global_position.distance_to(Vector3(4.5, 0.55, 1.2)) < 0.5, "fallen box should reset, at %s" % blue_box.global_position)

	print("vanishing_box_check: ALL PASSED")
	quit(0)


func _place(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
