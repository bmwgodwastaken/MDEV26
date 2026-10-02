class_name PlankSpwaner extends Node

@export var Marker3d:Marker3D
@export var Plank:PackedScene
@export var Spwan_Amount:int = 1
var last_spwan_planks:Array[RigidBody3D] = []


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if last_spwan_planks.is_empty() or last_spwan_planks.size() +1 <= Spwan_Amount:
		var ins:RigidBody3D = Plank.instantiate()
		get_tree().current_scene.add_child(ins)
		ins.global_position = Marker3d.global_position
		last_spwan_planks.append(ins)
		print("Spwaned!" + str(last_spwan_planks))
