extends Node3D
## Root script for a level. Every level starts in 2.5D with no keys, so progress doesn't leak
## between levels (or from the menu). _enter_tree runs before any child's _ready, so pieces
## that read the current view in _ready already see 2.5D.


func _enter_tree() -> void:
	PerspectiveManager.mode = PerspectiveManager.Mode.SOLID
	Inventory.clear()
	LevelFlow.next_level = ""
