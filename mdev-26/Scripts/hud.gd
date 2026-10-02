extends CanvasLayer
## Top-left row of the keys the player is holding (placeholder colored squares).

const ICON_SIZE := Vector2(32, 32)

var _row := HBoxContainer.new()


func _ready() -> void:
	_row.position = Vector2(16, 16)
	add_child(_row)
	Inventory.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for icon in _row.get_children():
		icon.queue_free()
	for id in Inventory.keys:
		var icon := ColorRect.new()
		icon.color = Color.from_string(id, Color.WHITE)
		icon.custom_minimum_size = ICON_SIZE
		_row.add_child(icon)
