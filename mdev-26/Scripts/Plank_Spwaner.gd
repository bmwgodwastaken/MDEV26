class_name PlankSpwaner extends Node
## Keeps Spwan_Amount planks alive: spawns a plank at Marker3d when there are fewer,
## so a plank that falls out of the world comes back. A level can have several spawners;
## each plank remembers the spawner that made it.

@export var Marker3d:Marker3D
@export var Plank:PackedScene
@export var Spwan_Amount:int = 1
var last_spwan_planks:Array[RigidBody3D] = []


func _process(_delta: float) -> void:
	if last_spwan_planks.size() < Spwan_Amount:
		var ins:GrabPlank = Plank.instantiate()
		ins.Plank_Spwaner = self
		get_parent().add_child(ins) # next to the spawner, so it works whatever the current scene is
		ins.global_position = Marker3d.global_position
		ins.global_rotation_degrees.y = 180
		last_spwan_planks.append(ins)
