extends AnimatedSprite3D
## Picks the player's animation (idle / walk / jump) and flips the picture left or right.
## Only reads the body's velocity, so it works with any controller.

## The art faces right; it is flipped while walking left.
@export var art_faces_right := true

@onready var body: CharacterBody3D = get_parent()


func _process(_delta: float) -> void:
	if absf(body.velocity.x) > 0.1:
		flip_h = (body.velocity.x < 0.0) == art_faces_right
	var moving := Vector2(body.velocity.x, body.velocity.z).length() > 0.1
	var next := &"jump" if not body.is_on_floor() else (&"walk" if moving else &"idle")
	if animation != next:
		play(next)
