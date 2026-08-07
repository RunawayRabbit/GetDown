extends Node
class_name PlayerModifier

## Abilities to add.
@export var abilities: Array[StringName] = []

func _enter_tree() -> void:
	var players = get_tree().get_node_count_in_group(&"player")
	if players == 0:
		for child in get_children():
			child.process_mode = Node.PROCESS_MODE_INHERIT

func _process(_delta:float) -> void:
	_try_add_abilities()
	
func _try_add_abilities() -> void:
	var group = get_tree().get_nodes_in_group(&"player")
	if not group.is_empty():
		var player = group[0] as CharacterController
		if not player: return
		for ability in abilities:
			player.add_ability(ability)
		set_process(false)
