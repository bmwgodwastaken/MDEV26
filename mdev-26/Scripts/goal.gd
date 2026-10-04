extends Node3D

@export_file("*.tscn") var Goal_path = ""

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("2.5DPlayer"):
		get_tree().change_scene_to_file(Goal_path)
