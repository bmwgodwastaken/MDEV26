extends SceneTree
## Headless check of Audio. Run from mdev-26/:
##   Godot.exe --headless --path . -s res://Tests/audio_check.gd
## Needs no real .wav: a fake stream is put in the cache where the file would be.


func _initialize() -> void:
	_run.call_deferred()


func _path(folder: String, sfx: String) -> String:
	return "res://Assets/Audio/%s/%s.wav" % [folder, sfx]


func _run() -> void:
	var audio = load("res://Scripts/Audio/audio.gd")
	var manager := root.get_node("PerspectiveManager")
	var before := root.get_child_count()
	audio.play("no_such_sound_sfx")
	assert(root.get_child_count() == before, "a missing .wav is skipped silently")

	var shared := AudioStreamWAV.new()
	var only_2d := AudioStreamWAV.new()
	audio._streams[_path("shared", "a_sfx")] = shared
	audio._streams[_path("2D", "b_sfx")] = only_2d
	manager.mode = 0
	assert(audio._find("a_sfx") == shared, "a shared sound plays in 2.5D")
	assert(audio._find("b_sfx") == null, "a 2D-only sound is not found in 2.5D")
	manager.mode = 1
	assert(audio._find("a_sfx") == shared, "a shared sound plays in 2D")
	assert(audio._find("b_sfx") == only_2d, "the 2D version is found in 2D")
	audio.play("a_sfx")
	assert(root.get_child_count() == before + 1, "a found sound starts a player")
	print("audio_check: ALL PASSED")
	quit(0)
