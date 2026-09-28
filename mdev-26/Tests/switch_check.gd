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

	print("switch_check: ALL PASSED")
	quit(0)


func _place(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
