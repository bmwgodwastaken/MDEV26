extends CanvasLayer
## Top-left row of the keys the player is holding: the key picture, tinted with the key's color.

const KEY_ICON := preload("res://Assets/Art/key_25d.png")
const ICON_SIZE := Vector2(44, 40) # the 11 x 10 pixel picture at 4x

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
		var icon := TextureRect.new()
		icon.texture = KEY_ICON
		icon.modulate = Color.from_string(id, Color.WHITE)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		icon.custom_minimum_size = ICON_SIZE
		_row.add_child(icon)
