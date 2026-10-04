class_name Audio
extends RefCounted
## Audio.play("jump_sfx") plays Assets/Audio/<2D or 2.5D>/jump_sfx.wav for the current view, or
## Assets/Audio/shared/jump_sfx.wav when there is no per-view version. A name with no .wav file
## yet is skipped silently, so the calls can stay in the code before the sounds exist.
## A plain class (not an autoload), so it works without any project setting.

const FOLDER := "res://Assets/Audio/"

static var _streams := {} # path -> AudioStream, or null for a file that doesn't exist


static func play(sfx: String) -> void:
	var stream := _find(sfx)
	var tree := Engine.get_main_loop() as SceneTree
	if not stream or not tree:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	tree.root.add_child(player)
	player.play()


static func _find(sfx: String) -> AudioStream:
	var view := "2D" if PerspectiveManager.mode == PerspectiveManager.Mode.FLAT else "2.5D"
	for folder in [view, "shared"]:
		var path := "%s%s/%s.wav" % [FOLDER, folder, sfx]
		if not _streams.has(path):
			_streams[path] = load(path) if ResourceLoader.exists(path) else null
		if _streams[path]:
			return _streams[path]
	return null
