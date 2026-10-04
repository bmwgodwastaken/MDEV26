extends SceneTree
## Headless solvability check for level 1 and 2. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/levels_check.gd

var player: CharacterBody3D
var switcher: Node
var interactor: Node
var inventory: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	inventory = root.get_node("Inventory")
	await _level1()
	await _level2()
	print("levels_check: ALL PASSED")
	quit(0)


func _load(path: String) -> Node:
	var level: Node = load(path).instantiate()
	root.add_child(level)
	player = level.get_node("2_5DCharacter")
	switcher = player.get_node("PerspectiveSwitcher")
	interactor = player.get_node_or_null("Interactor")
	await _frames(20)
	return level


## No two floating texts may overlap when seen flat from the side (the 2D view, where depth is ignored).
func _assert_no_text_overlap(level: Node) -> void:
	var rects := {}
	for label in level.find_children("*", "Label3D", true, false):
		var box: AABB = label.global_transform * label.get_aabb()
		assert(box.size.x > 0.5, "%s has no measurable size" % label.name)
		rects[label.name] = Rect2(box.position.x, box.position.y, box.size.x, box.size.y)
	var names := rects.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			assert(not rects[names[i]].intersects(rects[names[j]]), "texts overlap: %s and %s" % [names[i], names[j]])


func _level1() -> void:
	var level := await _load("res://Scenes/Levels/level_01_tutorial.tscn")
	_assert_no_text_overlap(level)
	var goal = level.get_node("Goal")
	goal.next_scene = "" # stay in this scene for the check
	var reached := [false]
	goal.reached.connect(func(): reached[0] = true)

	# Movement: A/D works, and the wall blocks in 2D but can be walked around in 2.5D.
	await _place(Vector3(19.5, 1.1, 0))
	assert(switcher.toggle(), "switch to 2D before the wall")
	Input.action_press("right")
	await _frames(60)
	Input.action_release("right")
	assert(player.global_position.x > 20.0 and player.global_position.x < 21.4, "wall must block in 2D, x=%s" % player.global_position.x)
	assert(switcher.toggle(), "switch back to 2.5D")
	await _place(Vector3(19.5, 1.1, 1.2))
	Input.action_press("right")
	await _frames(100)
	Input.action_release("right")
	assert(player.global_position.x > 24.0, "should walk around the wall in 2.5D, x=%s" % player.global_position.x)

	# Vase: hidden from the front, reachable from behind, vase fades while behind it.
	await _place(Vector3(29, 1.1, 1.8))
	assert(interactor.find_target() == null, "vase hides the red key from the front")
	await _place(Vector3(29, 1.1, -1.0))
	var key = interactor.find_target()
	assert(key and key.name == "RedKey", "red key reachable from behind the vase")
	assert(level.get_node("Vase")._material.albedo_color.a < 1.0, "vase fades when player is behind it")
	key.interact()
	assert(inventory.has_key("red"), "red key picked up")

	# Red door opens with the red key.
	await _place(Vector3(32.8, 1.1, 0))
	var lock = interactor.find_target()
	assert(lock and lock.get_parent().name == "RedDoor" and lock.get_prompt() == "E  Unlock", "red door offers unlock")
	lock.interact()
	await _frames(2)
	assert(not level.has_node("RedDoor"), "red door open")

	# Painting key only exists in 2D.
	await _place(Vector3(40, 1.1, 0))
	assert(interactor.find_target() == null, "painting key must not exist in 2.5D")
	assert(switcher.toggle(), "switch to 2D at the painting")
	key = interactor.find_target()
	assert(key and key.name == "BlueKey", "blue key reachable in 2D")
	key.interact()
	assert(inventory.has_key("blue") and level.get_node("HUD").get_child(0).get_child_count() == 1, "blue key picked up and shown in HUD")

	# Blue door, then the exit (reachable in 2D too).
	await _place(Vector3(42.8, 1.1, 0))
	lock = interactor.find_target()
	assert(lock and lock.get_parent().name == "BlueDoor", "blue door offers unlock")
	lock.interact()
	await _frames(2)
	assert(not level.has_node("BlueDoor"), "blue door open")
	await _place(Vector3(49, 1.1, 0))
	assert(reached[0], "level 1 exit reached")

	level.queue_free()
	await _frames(3)


func _level2() -> void:
	var level := await _load("res://Scenes/Levels/level_02_vanishing_box.tscn")
	_assert_no_text_overlap(level)
	assert(not inventory.has_key("red") and root.get_node("PerspectiveManager").mode == 0, "new level starts clean in 2.5D")
	var goal = level.get_node("Goal")
	var reached := [false]
	goal.reached.connect(func(): reached[0] = true)
	var box = level.get_node("BlueBox")
	var plate = level.get_node("PlateBlue")
	var door = level.get_node("DoorBlue/Panel")

	# Push the box onto the plate: the door opens in 2.5D.
	assert(not plate.pressed and door.visible, "door starts closed")
	await _place(Vector3(2.5, 1.1, 0.8))
	Input.action_press("right")
	await _frames(260)
	Input.action_release("right")
	assert(box.global_position.x > 10.5, "box pushed to the plate, x=%s" % box.global_position.x)
	assert(plate.pressed and not door.visible, "plate pressed, door open in 2.5D")

	# 2D: the box vanishes and the door closes; cross the gap.
	assert(switcher.toggle(), "switch to 2D")
	await _frames(5)
	assert(not plate.pressed and door.visible, "door closes in 2D")
	await _place(Vector3(14, 1.1, 0.8))
	await _place(Vector3(18, 1.1, 0.8))

	# Back to 2.5D on the far platform: the box returns, the door opens, walk to the exit.
	assert(switcher.toggle(), "switch to 2.5D on the far platform")
	await _frames(5)
	assert(plate.pressed and not door.visible, "door reopens in 2.5D")
	Input.action_press("right")
	await _frames(70)
	Input.action_release("right")
	assert(player.global_position.x > 21.0, "walked through the door, x=%s" % player.global_position.x)
	await _place(Vector3(25, 1.1, -11))
	assert(reached[0], "level 2 exit reached")

	level.queue_free()
	await _frames(3)


func _place(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
