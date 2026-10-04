class_name KeyPickup
extends Interactable
## A key the player picks up with E. Defaults to existing only in 2.5D;
## set faction to FLAT for a key that only exists in 2D (e.g. inside a painting).

signal picked_up(key_id: String)

@export var key_id := "red"


func _init() -> void:
	faction = WorldObject.Faction.SOLID


func _ready() -> void:
	super()
	# The key picture is grey, so any key_id color works: tint it. No picture = colored box.
	var pictures := find_children("*", "Sprite3D", true, false)
	for picture in pictures:
		picture.modulate = Color.from_string(key_id, Color.WHITE)
	if pictures.is_empty():
		_add_placeholder(Vector3(0.3, 0.3, 0.3), Color.from_string(key_id, Color.WHITE))


func get_prompt() -> String:
	return "E  Pick up %s key" % key_id


func interact() -> void:
	Inventory.add_key(key_id)
	picked_up.emit(key_id)
	remove_from_group("interactable")
	queue_free()
