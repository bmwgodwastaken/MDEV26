extends SceneTree
## Headless check of the menus. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/menu_check.gd
##   - main menu -> level selector -> level 1 / level 2
##   - the Q joke: pressing Q drops the Play button onto Quit and the game would quit


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://Scenes/main_menu.tscn", "game should start at the main menu")

	# Play (clicked with the mouse ray) opens the level selector.
	var menu := _open("res://Scenes/main_menu.tscn")
	await _frames(3)
	assert(root.get_node("PerspectiveManager").mode == 1, "menu starts in the flat (2D) view")
	assert(menu.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "flat menu uses the orthographic camera")
	var play_on_screen: Vector2 = menu.camera.unproject_position(menu.play.global_position)
	assert(menu._pick(play_on_screen) == "Play", "mouse ray should hit the Play button")
	menu.press("Play")
	await _frames(3)
	assert(current_scene.name == "LevelSelector", "Play should open the level selector, got %s" % current_scene.name)

	var buttons := current_scene.get_node("GridContainer").get_children()
	assert(buttons.size() >= 2, "level selector should have buttons for levels 1 and 2")
	buttons[0].button_down.emit()
	await _frames(3)
	assert(current_scene.name == "Level01Tutorial", "button 1 should open level 1, got %s" % current_scene.name)

	_open("res://Scenes/level_selector.tscn")
	await _frames(3)
	current_scene.get_node("GridContainer").get_children()[1].button_down.emit()
	await _frames(3)
	assert(current_scene.name == "Level02VanishingBox", "button 2 should open level 2, got %s" % current_scene.name)

	# Credits slide in and out.
	menu = _open("res://Scenes/main_menu.tscn")
	await _frames(3)
	menu.press("Credits")
	assert(menu.credits_open, "credits should open")
	await create_timer(0.5).timeout
	var width: float = menu.get_viewport().get_visible_rect().size.x
	assert(menu.credits_panel.position.x < width - 100.0, "credits panel should have slid on screen")
	menu.press("Credits")
	assert(not menu.credits_open, "credits should close")

	# The joke: Q switches to 2.5D, Play falls onto Quit, the game quits.
	menu = _open("res://Scenes/main_menu.tscn")
	menu.really_quit = false
	var events := []
	menu.landed.connect(func(): events.append("landed"))
	menu.quit_requested.connect(func(): events.append("quit"))
	await _frames(3)
	var start_y: float = menu.play.global_position.y
	await _frames(60)
	assert(is_equal_approx(menu.play.global_position.y, start_y), "Play stays put while the menu is flat")

	var q := InputEventAction.new()
	q.action = "switch_perspective"
	q.pressed = true
	menu._unhandled_input(q)
	assert(menu.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Q switches to the 2.5D camera")
	assert(not menu.warning_sign.visible, "the warning sign goes away")
	await _frames(120)
	assert(menu.play.global_position.y < start_y - 1.0, "Play should fall, y=%s" % menu.play.global_position.y)
	assert(events.has("landed"), "Play should land on Quit")
	await create_timer(1.5).timeout
	assert(events.has("quit"), "the game should quit after Play lands on Quit")

	print("menu_check: ALL PASSED")
	quit(0)


func _open(path: String) -> Node:
	if current_scene:
		current_scene.free()
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	return scene


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
