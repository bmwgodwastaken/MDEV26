extends Node
## Autoload. Keys the player is holding, by id (e.g. "red"). The id doubles as the placeholder color name.

signal changed

var keys: Array[String] = []


func add_key(id: String) -> void:
	keys.append(id)
	changed.emit()


func has_key(id: String) -> bool:
	return id in keys


## Removes one key with this id (keys are used up when they open a door).
func use_key(id: String) -> void:
	keys.erase(id)
	changed.emit()


func clear() -> void:
	keys.clear()
	changed.emit()
