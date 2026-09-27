extends Camera3D

var player:CharacterBody3D
var Vis:VisibleOnScreenNotifier3D
var start_pos_z:float
@export var offset = 1




func _ready() -> void:
	player = get_tree().get_first_node_in_group("2.5DPlayer")
	if player:
		start_pos_z = player.global_position.z
		Vis = player. visible_on_screen_notifier_3d



func _process(_delta: float) -> void:
	if not player.global_position.x == global_position.x:
		global_position.x = player.global_position.x
