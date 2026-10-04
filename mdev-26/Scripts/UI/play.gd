extends Button

@export_file("*.tscn") var Level_Selector = ""



func _ready() -> void:
	mouse_entered.connect(Audio.play.bind("menu_hover_sfx"))


func _on_button_down() -> void:
	Audio.play("menu_confirm_sfx")
	get_tree().change_scene_to_file(Level_Selector)
