extends Node
class_name CharacterState

var controller: CharacterController
var state_machine: CharacterStateMachine

## Called once when this state becomes active.
## Previous_state_name can be an empty string. (ie: when starting cold.)
func enter(_previous_state_name: String) -> void:
	pass

## Called once when this state is about to be replaced.
func exit() -> void:
	pass

## Called every physics frame while this state is active.
func physics_update(_delta: float) -> void:
	pass
