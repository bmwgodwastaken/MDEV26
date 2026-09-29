extends Button

@export_file("*.tscn") var Button_path = ""



func _on_button_down() -> void:
	get_tree().change_scene_to_file(Button_path)
