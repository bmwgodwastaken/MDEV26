extends SceneTree
## Headless check of the plank system and level 3. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/plank_check.gd
## Also look at the output: it must not print any "ERROR:" lines.

var player: CharacterBody3D
var switcher: Node
var pm: Node
var inv: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	pm = root.get_node("PerspectiveManager")
	inv = root.get_node("Inventory")
	await _level3()
	await _tutorial()
	print("plank_check: ALL PASSED")
	quit(0)


func _open(path: String) -> Node:
	if current_scene:
		current_scene.free()
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("2_5DCharacter")
	switcher = player.get_node("PerspectiveSwitcher")
	return scene


func _planks() -> Array:
	return get_nodes_in_group("Grabble")


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _press(action: String, n := 3) -> void:
	Input.action_press(action)
	await _frames(n)
	Input.action_release(action)
	await _frames(2)


func _level3() -> void:
	var level := _open("res://Scenes/Levels/level_03_plank_bridge.tscn")
	await _frames(40)
	var goal = level.get_node("Goal")
	var reached := [false]
	goal.reached.connect(func(): reached[0] = true)

	# Texts must not overlap in the flat view.
	var rects := {}
	for label in level.find_children("*", "Label3D", true, false):
		var box: AABB = label.global_transform * label.get_aabb()
		rects[label.name] = Rect2(box.position.x, box.position.y, box.size.x, box.size.y)
	var names := rects.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			assert(not rects[names[i]].intersects(rects[names[j]]), "texts overlap: %s and %s" % [names[i], names[j]])

	# Two spawners, one plank each; each plank knows its own spawner.
	var planks := _planks()
	assert(planks.size() == 2, "two planks should spawn, got %d" % planks.size())
	var owners := planks.map(func(p): return p.Plank_Spwaner.name)
	assert("PlankSpwaner" in owners and "PlankSpwaner2" in owners, "each plank is tied to its own spawner: %s" % [owners])
	for p in planks:
		assert(p.collision_layer == 1 and p.get_node("FlatBody").collision_layer == 2, "plank has a 2.5D and a 2D collider")

	# A plank that falls out of the world is replaced by ITS spawner only.
	var lost = planks[1]
	var lost_owner = lost.Plank_Spwaner
	var kept = planks[0]
	lost.global_position.y = -30.0
	await _frames(5)
	assert(not is_instance_valid(lost) and is_instance_valid(kept), "only the fallen plank is deleted")
	assert(_planks().size() == 2, "the fallen plank is replaced")
	assert(lost_owner.last_spwan_planks.size() == 1 and lost_owner.last_spwan_planks[0] != lost, "its own spawner made the new plank")

	# G only grabs what is inside the grab area right now.
	player.global_position = Vector3(0.5, 1.1, 0.3)
	await _frames(15)
	await _press("Pick_up")
	assert(not player.Is_Grabbing, "G with no plank in reach grabs nothing")
	player.global_position = Vector3(2.8, 1.1, 0.3)
	await _frames(15)
	await _press("Pick_up")
	assert(player.Is_Grabbing and player.COIB.Plank_Spwaner.name == "PlankSpwaner", "G grabs the plank next to the player")
	var plank1 = player.COIB

	# Carry plank 1 to the first gap and drop it across (2.5D).
	player.global_position = Vector3(10.0, 1.1, 0.3) # plank's left end lands at x = 11.4, gap is 12..19.6
	await _frames(5)
	await _press("Pick_up")
	assert(not player.Is_Grabbing, "G drops the plank")
	await _frames(90)
	assert(plank1.global_position.y > -1.0, "plank rests across the gap, y=%s" % plank1.global_position.y)

	# Now G from far away must not pull it back.
	player.global_position = Vector3(5.0, 1.1, 0.3)
	await _frames(15)
	await _press("Pick_up")
	assert(not player.Is_Grabbing, "G from far away must not grab the dropped plank")

	# Walk over plank 1 in 2.5D.
	player.global_position = Vector3(10.0, 1.1, 0.3)
	await _frames(15)
	Input.action_press("right")
	await _frames(150)
	Input.action_release("right")
	assert(player.global_position.x > 20.5 and player.global_position.y > 0.5, "should cross gap 1 on the plank, at %s" % player.global_position)

	# Plank 2: grab it on the middle platform, drop it across gap 2 (2.5D).
	player.global_position = Vector3(23.0, 1.1, 0.3)
	await _frames(15)
	await _press("Pick_up")
	assert(player.Is_Grabbing and player.COIB.Plank_Spwaner.name == "PlankSpwaner2", "grabbed plank 2")
	var plank2 = player.COIB
	player.global_position = Vector3(29.94, 1.1, 0.3) # left end at x = 31.3, gap is 32..39.6
	await _frames(5)
	await _press("Pick_up")
	await _frames(90)
	assert(plank2.global_position.y > -1.0, "plank 2 rests across gap 2")

	# The far platform is 12 m back in depth: only reachable in 2D, over the plank.
	player.global_position = Vector3(31.0, 1.1, 0.3)
	await _frames(15)
	assert(switcher.toggle(), "switch to 2D at gap 2")
	Input.action_press("right")
	await _frames(200)
	Input.action_release("right")
	assert(player.global_position.x > 41.0 and player.global_position.y > 0.5, "should cross gap 2 over the plank in 2D, at %s" % player.global_position)

	# The exit works in 2D.
	player.global_position = Vector3(51.0, 1.1, 0.3)
	await _frames(20)
	assert(reached[0], "level 3 exit reached")


func _tutorial() -> void:
	# The plank tutorial now resets the view and keys like the other levels.
	pm.mode = 1
	inv.add_key("red")
	var level := _open("res://Scenes/tutorial.tscn")
	await _frames(20)
	assert(pm.mode == 0 and not inv.has_key("red"), "tutorial should start in 2.5D with no keys")

	# Its goal changes scene (deferred, no physics-callback error).
	player.global_position = level.get_node("Goal").global_position
	await _frames(20)
	assert(current_scene.name == "LevelComplete", "goal should open the level complete screen, got %s" % current_scene.name)
