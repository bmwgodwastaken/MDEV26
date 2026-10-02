extends Node
## Child of the player. After the player moves, any PushBox it bumped into sideways is
## pushed away at PUSH_SPEED. Doesn't touch the player's movement script.
## Runs after the parent's _physics_process, so the slide collisions are fresh.

const PUSH_SPEED := 2.5

@onready var body: CharacterBody3D = get_parent()


func _physics_process(delta: float) -> void:
	var pushed: Array[PushBox] = []
	for i in body.get_slide_collision_count():
		var hit := body.get_slide_collision(i)
		var box := hit.get_collider() as PushBox
		if not box or box in pushed:
			continue
		var normal := hit.get_normal()
		normal.y = 0.0
		if normal.length() < 0.5:
			continue # standing on top of the box, not pushing it
		box.push(-normal.normalized() * PUSH_SPEED * delta)
		pushed.append(box)
