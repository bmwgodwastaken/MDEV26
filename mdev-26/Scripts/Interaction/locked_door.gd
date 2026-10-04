class_name LockedDoor
extends Interactable
## Child of a door WorldObject (neutral, so it blocks in both modes).
## E with the matching key uses up the key and removes the door.

signal unlocked(key_id: String)
signal denied(key_id: String)

@export var key_id := "red"


func _ready() -> void:
	super()
	_add_placeholder(Vector3(1.05, 0.3, 4.05), Color.from_string(key_id, Color.WHITE)) # colored band showing which key


func get_prompt() -> String:
	return "E  Unlock" if Inventory.has_key(key_id) else "Needs %s key" % key_id


func interact() -> void:
	if not Inventory.has_key(key_id):
		denied.emit(key_id)
		return
	Inventory.use_key(key_id)
	unlocked.emit(key_id)
	remove_from_group("interactable")
	get_parent().queue_free()


func sight_exclude() -> Array[RID]:
	var rids: Array[RID] = []
	for body in get_parent().find_children("*", "CollisionObject3D", true, false):
		rids.append(body.get_rid())
	return rids
