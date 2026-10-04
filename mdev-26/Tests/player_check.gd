extends SceneTree
## Headless check of the player's sprite: animation choice, facing, size and feet alignment. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/player_check.gd


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	var level: Node = load("res://Scenes/Levels/level_03_plank_bridge.tscn").instantiate()
	root.add_child(level)
	await _frames(40)
	var player: CharacterBody3D = level.get_node("2_5DCharacter")
	var sprite: AnimatedSprite3D = player.get_node("Sprite3D")

	# The panda is set up: right animations, 4 walk frames, 2 idle frames.
	assert(sprite.sprite_frames.get_frame_count("walk") == 4, "walk has 4 frames")
	assert(sprite.sprite_frames.get_frame_count("idle") == 2, "idle has 2 frames")
	assert(sprite.sprite_frames.has_animation("jump"), "jump animation exists")

	# Feet on the bottom of the capsule (2 m tall, centre at 0): sprite bottom edge at y = -1.
	var frame_height := sprite.sprite_frames.get_frame_texture("idle", 0).get_height() * sprite.pixel_size
	assert(is_equal_approx(sprite.position.y - frame_height / 2.0, -1.0), "feet line up with the bottom of the capsule")

	assert(sprite.animation == &"idle", "idle when standing still, got %s" % sprite.animation)

	Input.action_press("right")
	await _frames(15)
	assert(sprite.animation == &"walk" and not sprite.flip_h, "walking right plays walk, not flipped")
	Input.action_release("right")
	Input.action_press("left")
	await _frames(15)
	assert(sprite.animation == &"walk" and sprite.flip_h, "walking left plays walk, flipped")
	Input.action_release("left")
	await _frames(15)
	assert(sprite.animation == &"idle" and sprite.flip_h, "stopping goes back to idle and keeps facing left")

	Input.action_press("ui_accept")
	await _frames(3)
	Input.action_release("ui_accept")
	await _frames(8)
	assert(sprite.animation == &"jump", "jump animation while in the air, got %s" % sprite.animation)
	await _frames(90)
	assert(player.is_on_floor() and sprite.animation == &"idle", "back to idle after landing, got %s" % sprite.animation)

	print("player_check: ALL PASSED")
	quit(0)
