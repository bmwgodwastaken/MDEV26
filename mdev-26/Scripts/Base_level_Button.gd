extends Button

@export_file("*.tscn") var LevelToLoad
var is_played_before = false

func _ready() -> void:
	self.button_down.connect(_on_button_down)
	mouse_entered.connect(Audio.play.bind("menu_hover_sfx"))
	
func _on_button_down() -> void:
	Audio.play("menu_confirm_sfx")
	get_tree().change_scene_to_file(LevelToLoad)
	is_played_before = true
