extends SceneTree
## Headless check for the perspective switch. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/switch_check.gd

var player: CharacterBody3D
var switcher: Node
var pm: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	pm = root.get_node("PerspectiveManager")
	var level: Node = load("res://Scenes/switch_test.tscn").instantiate()
	root.add_child(level)
	player = level.get_node("2_5DCharacter")
	switcher = player.get_node("PerspectiveSwitcher")

	# 0. 2.5D camera must look down at the level, not up at the sky.
	var cam: Camera3D = level.get_node("CameraController2_5D")
	assert(-cam.global_basis.z.y < 0, "2.5D camera should point downward")

	# 1. Next to the L1 wall in 2.5D, switching to 2D would put us inside it -> refused.
	await _place(Vector3(5, 1.1, 1.5))
	assert(not switcher.toggle(), "switch into wall should be refused")
	assert(pm.mode == 0, "mode should still be SOLID")

	# 2. L2 depth gap: 2.5D at x=14,z=0 has no floor -> falls.
	await _place(Vector3(14, 1.1, 0))
	await _frames(30)
	assert(player.global_position.y < -1.0, "2.5D should fall through the depth gap")

	# 3. Same spot in 2D: the far platform (z=-12) is under us -> stands.
	await _place(Vector3(11.5, 1.1, 0))
	assert(switcher.toggle(), "switch to 2D should work on open floor")
	await _place(Vector3(14, 1.1, 0))
	await _frames(30)
	assert(player.global_position.y > -0.1, "2D should stand on the far platform")
	Input.action_press("up")
	await _frames(20)
	Input.action_release("up")
	assert(is_equal_approx(player.global_position.z, 0.0), "W/S must not move depth in 2D")

	# 4. Back to 2.5D: snapped onto the far platform's real depth (z in -14..-10).
	assert(switcher.toggle(), "switch back to 2.5D should work")
	var z := player.global_position.z
	assert(z > -14 and z < -10, "should snap to far platform depth, got z=%s" % z)
	await _frames(30)
	assert(player.global_position.y > -0.1, "should still be standing after snap")
	assert(-cam.global_basis.z.y < 0, "camera should point downward again after 2D")

	var interactor: Node = player.get_node("Interactor")
	var inventory: Node = root.get_node("Inventory")
	var vase = level.get_node("Vase_SolidScenery")

	# 5. Red key behind the vase: in range but hidden from the front, visible from behind.
	await _place(Vector3(32, 1.1, -10.2))
	assert(interactor.find_target() == null, "vase should hide the key from the front")
	await _place(Vector3(32, 1.1, -12.8))
	var red_key = interactor.find_target()
	assert(red_key and red_key.name == "RedKey_BehindVase", "key should be interactable from behind the vase")
	assert(vase._material.albedo_color.a < 1.0, "vase should fade while player is behind it")
	red_key.interact()
	assert(inventory.has_key("red"), "red key should be in inventory")

	# 6. Red door opens with the red key, and the key is used up.
	await _place(Vector3(33.8, 1.1, -12))
	var red_door = interactor.find_target()
	assert(red_door and red_door.get_parent().name == "RedDoor" and red_door.get_prompt() == "E  Unlock", "red door should offer unlock")
	red_door.interact()
	assert(not inventory.has_key("red"), "red key should be used up")
	await _frames(2)
	assert(not level.has_node("RedDoor"), "red door should be gone")

	# 7. Blue key (in the painting) only exists in 2D.
	await _place(Vector3(38.5, 1.1, -12))
	assert(interactor.find_target() == null, "2D-only key must not be interactable in 2.5D")
	assert(switcher.toggle(), "switch to 2D near painting")
	var blue_key = interactor.find_target()
	assert(blue_key and blue_key.name == "BlueKey_InPainting", "blue key should be interactable in 2D")

	# 8. Blue door without the key says what's needed and stays shut; with it, it opens.
	await _place(Vector3(39.8, 1.1, -12))
	var blue_door = interactor.find_target()
	assert(blue_door and blue_door.get_parent().name == "BlueDoor" and blue_door.get_prompt() == "Needs blue key", "door should ask for blue key")
	blue_door.interact()
	await _frames(2)
	assert(level.has_node("BlueDoor"), "door must stay locked without key")
	blue_key.interact()
	assert(level.get_node("HUD").get_child(0).get_child_count() == 1, "HUD should show one key icon")
	blue_door.interact()
	await _frames(2)
	assert(not level.has_node("BlueDoor"), "blue door should be gone")

	print("switch_check: ALL PASSED")
	quit(0)


func _place(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
