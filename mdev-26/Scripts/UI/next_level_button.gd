extends Button
## "Next Level" on the Level Complete screen: opens the level the exit that sent us here points to.
## Hidden when there is none (last level, or the screen was opened some other way).


func _ready() -> void:
	visible = LevelFlow.next_level != ""
	mouse_entered.connect(Audio.play.bind("menu_hover_sfx"))
	pressed.connect(func() -> void:
		Audio.play("menu_confirm_sfx")
		get_tree().change_scene_to_file(LevelFlow.next_level))
