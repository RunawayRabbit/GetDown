extends Node
class_name LevelManager

# Please put all the doors in here, sorry in advance.
@export var doors:Array[Door]

var _scene_file_path: String = ""

func initialize(game_manager: GameManager, path: String) -> void:
	_scene_file_path = path
	for door in doors:
		door.initialize(game_manager)
