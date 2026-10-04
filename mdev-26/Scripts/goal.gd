extends Node3D

@export_file("*.tscn") var Goal_path = ""

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("2.5DPlayer"):
		# Deferred: changing scene inside a physics signal frees physics bodies mid-callback.
		get_tree().change_scene_to_file.call_deferred(Goal_path)
