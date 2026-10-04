extends Control
## The Level Complete screen. When the exit's zoom-in handed over to it, it zooms out from black:
## the whole screen starts big and transparent and settles to normal size.

const ZOOM_FROM := 3.0
const ZOOM_TIME := 0.9


func _ready() -> void:
	if not LevelFlow.play_intro:
		return
	LevelFlow.play_intro = false
	pivot_offset = get_viewport_rect().size / 2.0
	scale = Vector2(ZOOM_FROM, ZOOM_FROM)
	modulate.a = 0.0

	var layer := CanvasLayer.new()
	layer.layer = 100
	var cover := ColorRect.new() # the black the zoom-in ended on, fading away
	cover.color = Color.BLACK
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cover)
	add_child(layer)

	var intro := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro.tween_property(self, "scale", Vector2.ONE, ZOOM_TIME)
	intro.tween_property(self, "modulate:a", 1.0, ZOOM_TIME * 0.6)
	intro.tween_property(cover, "color:a", 0.0, ZOOM_TIME * 0.7)
	intro.chain().tween_callback(layer.queue_free)
