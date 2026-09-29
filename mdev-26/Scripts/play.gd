extends Button

@export_file("*.tscn") var Level_Selector = ""



func _on_button_down() -> void:
	get_tree().change_scene_to_file(Level_Selector)
