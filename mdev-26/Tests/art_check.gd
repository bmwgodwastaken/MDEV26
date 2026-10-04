extends SceneTree
## Headless check that the artist's pictures are wired into the levels. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/art_check.gd
## (It can't judge how things look; record frames with --write-movie for that.)

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


func _run() -> void:
	var pm := root.get_node("PerspectiveManager")
	for path: String in LEVELS:
		if current_scene:
			current_scene.free()
		pm.mode = 0
		var level: Node = load(path).instantiate()
		root.add_child(level)
		current_scene = level
		await _frames(10)
		var level_name: String = path.get_file()

		# Every floor / door piece has its pictures (two for floors, one for doors).
		var dressed := 0
		for piece in level.find_children("*", "GeometryInstance3D", true, false):
			if piece.get_script() and "art" in piece and piece.art != 0:
				var pictures: int = piece.get_children().filter(func(c): return c is MeshInstance3D).size()
				assert(pictures == (2 if piece.art == 1 else 1), "%s: %s should have its pictures, has %d" % [level_name, piece.name, pictures])
				dressed += 1
		assert(dressed >= 3, "%s: floors and doors should be dressed, only %d" % [level_name, dressed])

		# The wall behind the level is built (a plain wall plus the top band).
		var backdrop := level.get_node("Backdrop")
		assert(backdrop.get_child_count() == 2, "%s: backdrop should be built" % level_name)

		# The flag shows the 2.5D picture, then the 2D picture after switching, standing on the floor either way.
		var flag: Sprite3D = level.get_node("Goal/Flag")
		assert(flag.texture == flag.texture_25d, "%s: flag shows its 2.5D picture" % level_name)
		var feet_25d := flag.position.y - flag.texture.get_height() * flag.pixel_size / 2.0
		pm.set_mode(1)
		assert(flag.texture == flag.texture_2d, "%s: flag shows its 2D picture in 2D" % level_name)
		var feet_2d := flag.position.y - flag.texture.get_height() * flag.pixel_size / 2.0
		assert(is_equal_approx(feet_25d, feet_2d) and is_equal_approx(feet_2d, flag.ground_y), "%s: flag stands on the floor in both views" % level_name)

	# Planks have the 2.5D top picture and the 2D side pictures.
	var plank: Node = load("res://Scenes/plank.tscn").instantiate()
	for part in ["ArtTop", "ArtFront", "ArtBack"]:
		assert(plank.has_node(part), "plank has %s" % part)
	plank.free()

	print("art_check: ALL PASSED")
	quit(0)
