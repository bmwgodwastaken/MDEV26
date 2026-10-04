extends SceneTree
## Plays level 4 from start to exit with real input (pushing, grabbing, jumping, switching view).
## Teleports only to skip plain walking. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/level4_check.gd

var level: Node
var player: CharacterBody3D
var switcher: Node
var interactor: Node
var inventory: Node


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _place(pos: Vector3, settle := 15) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await _frames(settle)


## Holds the given actions for n frames, then releases them.
func _hold(actions: Array, n: int) -> void:
	for a in actions:
		Input.action_press(a)
	await _frames(n)
	for a in actions:
		Input.action_release(a)
	await _frames(2)


## Holds `action` until `done` returns true (or max frames), then releases.
func _hold_until(action: String, done: Callable, max_frames: int) -> void:
	Input.action_press(action)
	for i in max_frames:
		await physics_frame
		if done.call():
			break
	Input.action_release(action)
	await _frames(10)


## The level's walls and gaps can't be skipped: jumps that would bypass a puzzle must fail.
func _no_shortcuts() -> void:
	level = load("res://Scenes/Levels/level_04_core.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	player = level.get_node("2_5DCharacter")
	switcher = player.get_node("PerspectiveSwitcher")
	await _frames(40)

	# From the ledge top, the cage door (6 m tall, 4 m away) can't be hopped over.
	await _place(Vector3(21.5, 3.9, -1.0))
	Input.action_press("right")
	await _hold(["ui_accept"], 3)
	await _frames(70)
	Input.action_release("right")
	await _frames(60)
	assert(player.global_position.x < 25.7, "cage door must not be jumpable from the ledge, x=%s" % player.global_position.x)

	# The chasm (7.6 m) can't be jumped from its edge, even at full speed.
	await _place(Vector3(43.3, 1.1, -10.6))
	Input.action_press("right")
	await _hold(["ui_accept"], 3)
	await _frames(70)
	Input.action_release("right")
	await _frames(45)
	assert(player.global_position.y < -1.0, "chasm must not be jumpable, y=%s" % player.global_position.y)

	# The red bridge pit (8 m) can't be jumped in 2.5D either.
	await _place(Vector3(57.5, 1.1, -10.6))
	Input.action_press("right")
	await _hold(["ui_accept"], 3)
	await _frames(70)
	Input.action_release("right")
	await _frames(45)
	assert(player.global_position.y < -1.0, "red bridge pit must not be jumpable in 2.5D, y=%s" % player.global_position.y)
	level.free()
	await _frames(3)


func _run() -> void:
	inventory = root.get_node("Inventory")
	await _no_shortcuts()
	level = load("res://Scenes/Levels/level_04_core.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	player = level.get_node("2_5DCharacter")
	switcher = player.get_node("PerspectiveSwitcher")
	interactor = player.get_node("Interactor")
	var goal = level.get_node("Goal")
	goal.complete_scene = "" # stay in the level
	var reached := [false]
	goal.reached.connect(func(): reached[0] = true)
	var blue_box = level.get_node("BlueBox")
	var red_box = level.get_node("RedBox")
	var plate_blue = level.get_node("PlateBlue")
	var plate_red = level.get_node("PlateRed")
	await _frames(40)

	# --- The starting state: every door shut, the plank waiting behind the cage door.
	for door_name in ["CageDoor/Panel", "GoldDoor/Panel", "PlateDoor2D/Panel", "ExitDoor/Panel"]:
		assert(level.get_node(door_name).visible, "%s starts closed" % door_name)
	var plank = get_nodes_in_group("Grabble")[0]
	assert(plank.global_position.x > 26.0 and plank.global_position.x < 29.0, "plank starts in the cage corridor")

	# --- The ledge can't be reached without the box.
	await _place(Vector3(18, 1.1, 1.0))
	await _hold(["up", "ui_accept"], 3)
	await _hold(["up"], 40)
	await _frames(90) # let the jump finish
	assert(player.global_position.y < 2.0, "ledge must not be reachable without the box, y=%s" % player.global_position.y)

	# --- 1. Push the blue box along the walkway to the foot of the ledge.
	await _place(Vector3(10.0, 1.1, 1.0))
	await _hold_until("right", func(): return blue_box.global_position.x >= 18.0, 500)
	assert(blue_box.global_position.x > 17.5 and blue_box.global_position.x < 19.5, "box pushed under the ledge, x=%s" % blue_box.global_position.x)
	assert(blue_box.global_position.y > 0.3, "box stands on the floor")

	# --- 2. Climb: stand on the box, jump up onto the ledge.
	await _place(Vector3(blue_box.global_position.x, 2.1, blue_box.global_position.z), 20)
	assert(player.is_on_floor() and player.global_position.y > 1.9, "the box holds the player, y=%s" % player.global_position.y)
	Input.action_press("up")
	await _hold(["ui_accept"], 3)
	await _frames(45)
	Input.action_release("up")
	await _frames(10)
	assert(player.global_position.y > 3.5 and player.global_position.z < 0.8, "should be standing on the ledge, at %s" % player.global_position)

	# --- Three vases on the ledge: the key hides behind the middle one, seen only from behind.
	assert(level.has_node("DecoyVase1") and level.has_node("DecoyVase2"), "two decoy vases on the ledge")
	await _place(Vector3(18, 3.9, 0.2))
	assert(interactor.find_target() == null, "vase hides the gold key from the front")
	assert(level.get_node("GoldKey/Picture").modulate.a < 0.1, "the key picture is not visible from the front")
	await _place(Vector3(18, 3.9, -2.0), 45)
	assert(level.get_node("GoldKey/Picture").modulate.a > 0.9, "the key picture appears once you see it from behind")
	var key = interactor.find_target()
	assert(key and key.name == "GoldKey", "gold key reachable from behind the vase")
	assert(level.get_node("Vase/Picture").modulate.a < 1.0, "vase fades while behind it")
	key.interact()
	assert(inventory.has_key("gold"), "gold key picked up")

	# --- 3. Move the box onto the blue plate (this opens the cage door, 2.5D only).
	assert(level.get_node("CageDoor/Panel").visible, "cage door still shut while the box is at the ledge")
	await _place(Vector3(19.9, 1.1, 1.0))
	await _hold_until("left", func(): return blue_box.global_position.x <= 10.2, 500)
	assert(plate_blue.pressed, "box on the blue plate, box x=%s" % blue_box.global_position.x)
	assert(not level.get_node("CageDoor/Panel").visible, "cage door open in 2.5D")

	# --- 4. Take the plank out of the cage.
	await _place(Vector3(28.0, 1.1, 0.3))
	await _hold(["Pick_up"], 3)
	assert(player.Is_Grabbing, "grabbed the plank")
	await _place(Vector3(36.3, 1.1, 0.0))

	# --- 5. Unlock the gold door.
	var lock = interactor.find_target()
	assert(lock and lock.get_parent().name == "GoldDoor" and lock.get_prompt() == "E  Unlock", "gold door offers unlock")
	lock.interact()
	await _frames(3)
	assert(not level.has_node("GoldDoor"), "gold door open")

	# --- 6. Carry the plank to the far lane: through the door in 2D, then back to 2.5D on the far floor.
	assert(switcher.toggle(), "switch to 2D while carrying the plank")
	await _place(Vector3(40.5, 1.1, 0.0), 40) # the carried plank needs a moment to catch up after a teleport
	assert(switcher.toggle(), "switch back to 2.5D on the far lane")
	await _frames(20)
	assert(player.global_position.z < -10.0, "snapped onto the far lane, z=%s" % player.global_position.z)
	assert(player.Is_Grabbing and absf(plank.global_position.z - player.global_position.z) < 1.0, "the plank came along, plank z=%s player z=%s" % [plank.global_position.z, player.global_position.z])

	# --- 7. Drop the plank over the chasm and cross it.
	await _place(Vector3(42.0, 1.1, player.global_position.z), 10)
	await _hold(["Pick_up"], 3)
	assert(not player.Is_Grabbing, "dropped the plank")
	await _frames(100)
	assert(plank.global_position.y > -1.0 and plank.global_position.x > 42.5 and plank.global_position.x < 44.5, "plank lies across the chasm, at %s" % plank.global_position)
	await _hold(["right"], 135)
	assert(player.global_position.x > 52.0 and player.global_position.y > 0.5, "crossed the chasm on the plank, at %s" % player.global_position)

	# --- 8. Walk to the red box, switch to 2D and push it across the red bridge onto the red plate.
	await _hold_until("right", func(): return player.global_position.x >= 54.4, 120) # clear of the chest's 2D shadow
	assert(switcher.toggle(), "switch to 2D before the red box, at %s" % player.global_position)
	assert(red_box.exists_now(), "the red box exists in 2D")
	await _hold_until("right", func(): return red_box.global_position.x >= 71.0 and absf(red_box.velocity.x) < 0.1, 800)
	assert(red_box.global_position.x > 70.5 and red_box.global_position.x < 71.3, "red box stopped by the stopper on the plate, x=%s" % red_box.global_position.x)
	assert(plate_red.pressed, "red plate pressed")
	assert(not level.get_node("PlateDoor2D/Panel").visible, "the 2D door is open while the red box is on its plate")

	# --- 9. Hop over the box and stopper, through the open door.
	await _place(Vector3(69.3, 1.1, player.global_position.z))
	Input.action_press("right")
	await _hold(["ui_accept"], 3)
	await _frames(85)
	Input.action_release("right")
	await _frames(10)
	assert(player.global_position.x > 74.0 and player.is_on_floor(), "through the 2D door, at %s" % player.global_position)

	# --- 10. Paintings along the far lane: the key only shows right at the one that hides it.
	var green_key = level.get_node("GreenKey")
	var key_x: float = green_key.global_position.x
	var paintings := level.get_children().filter(func(n): return "Painting" in n.name)
	assert(paintings.size() >= 3, "three paintings along the far lane")
	for painting in paintings:
		if absf(painting.global_position.x - key_x) > 2.0: # a decoy
			await _place(Vector3(painting.global_position.x, 1.1, player.global_position.z), 45)
			assert(green_key.get_node("Picture").modulate.a < 0.1, "no key picture at the decoy painting at x=%s" % painting.global_position.x)
	await _place(Vector3(key_x - 0.8, 1.1, player.global_position.z), 45)
	assert(green_key.get_node("Picture").modulate.a > 0.9, "the key picture shows right at the real painting")
	var green = interactor.find_target()
	assert(green and green.name == "GreenKey", "green key found in the painting in 2D")
	green.interact()
	assert(inventory.has_key("green"), "green key picked up")

	# --- 11. The exit door wants the orange key, not the green one.
	await _place(Vector3(78.8, 1.1, player.global_position.z))
	lock = interactor.find_target()
	assert(lock and lock.get_parent().name == "ExitDoor" and lock.get_prompt() == "Needs orange key", "exit door asks for the orange key, got %s" % (lock.get_prompt() if lock else "nothing"))

	# --- 11b. Backtrack (2D): back over the door, stopper and red box, along the bridge, to the chest at the chasm landing.
	await _place(Vector3(72.7, 1.1, player.global_position.z))
	Input.action_press("left")
	await _hold(["ui_accept"], 3)
	await _frames(40)
	Input.action_release("left")
	await _frames(60)
	assert(player.global_position.x < 70.0 and player.is_on_floor(), "hopped back over the stopper and the red box, at %s" % player.global_position)
	await _hold(["left"], 150)
	assert(player.global_position.x < 58.0, "walked back over the red bridge in 2D, at %s" % player.global_position)

	# --- 11c. The green chest at the landing: opens with the painting key, the orange key is inside.
	var chest_x: float = level.get_node("GreenChest").global_position.x
	await _place(Vector3(chest_x + 1.6, 1.1, player.global_position.z), 30)
	assert(level.get_node("OrangeKey/Picture").modulate.a < 0.1, "the orange key is not visible while the chest is shut")
	var chest_lock = interactor.find_target()
	assert(chest_lock and chest_lock.get_parent().name == "GreenChest" and chest_lock.get_prompt() == "E  Unlock", "green chest offers unlock")
	chest_lock.interact()
	await _frames(40)
	assert(not level.has_node("GreenChest"), "chest open")
	assert(not inventory.has_key("green"), "the green key was used up")
	var orange = interactor.find_target()
	assert(orange and orange.name == "OrangeKey", "orange key now reachable")
	orange.interact()
	assert(inventory.has_key("orange"), "orange key picked up")

	# --- 11d. Back to the exit door and unlock it with the orange key.
	await _place(Vector3(78.8, 1.1, player.global_position.z), 20)
	lock = interactor.find_target()
	assert(lock and lock.get_parent().name == "ExitDoor" and lock.get_prompt() == "E  Unlock", "exit door offers unlock with the orange key")
	lock.interact()
	await _frames(3)
	assert(not level.has_node("ExitDoor"), "exit door open")

	# --- 12. The gauntlet: jump, switch view in mid-air, land on the platform of the other view.
	assert(switcher.toggle(), "switch to 2.5D for the first blue platform")
	await _frames(20)
	assert(player.global_position.z < -10.0, "on the far lane before the gauntlet, z=%s" % player.global_position.z)
	var lane_z: float = player.global_position.z
	await _place(Vector3(83.6, 1.1, lane_z))
	Input.action_press("right")
	await _hold(["ui_accept"], 3)
	await _frames(52)
	Input.action_release("right")
	await _frames(50)
	assert(player.is_on_floor() and player.global_position.x > 87.0 and player.global_position.x < 90.0, "landed on the first blue platform, at %s" % player.global_position)

	await _place(Vector3(89.3, 1.1, lane_z))
	Input.action_press("right")
	Input.action_press("ui_accept")
	await _frames(3)
	Input.action_release("ui_accept")
	await _frames(5)
	assert(switcher.toggle(), "switch to 2D in mid-air")
	await _frames(52)
	Input.action_release("right")
	await _frames(50)
	assert(player.is_on_floor() and player.global_position.x > 93.0 and player.global_position.x < 96.0, "landed on the red platform, at %s" % player.global_position)

	await _place(Vector3(95.3, 1.1, lane_z))
	Input.action_press("right")
	Input.action_press("ui_accept")
	await _frames(3)
	Input.action_release("ui_accept")
	await _frames(5)
	assert(switcher.toggle(), "switch to 2.5D in mid-air")
	await _frames(52)
	Input.action_release("right")
	await _frames(50)
	assert(player.is_on_floor() and player.global_position.x > 99.0 and player.global_position.x < 102.0, "landed on the second blue platform, at %s" % player.global_position)

	await _place(Vector3(101.3, 1.1, lane_z))
	Input.action_press("right")
	Input.action_press("ui_accept")
	await _frames(3)
	Input.action_release("ui_accept")
	await _frames(60)
	Input.action_release("right")
	await _frames(40)
	assert(reached[0], "exit reached, player at %s" % player.global_position)

	print("level4_check: ALL PASSED")
	quit(0)
