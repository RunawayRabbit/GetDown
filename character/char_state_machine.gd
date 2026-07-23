
class_name CharacterStateMachine
extends Node

## Name of the state node to enter on _ready(). Must match a child node name. Sorry for the jank.
@export var initial_state_name: String = "idle"

# TODO: I don't really like how fragile this is. It just kind fell out of the general stress of
# "I don't have time to do a good job", and it might be good enough but.. be prepared to spend
# time refactoring this away from node-based and into RefCounted

var current_state: CharacterState
var _states: Dictionary = {}


func _ready() -> void:
	var controller := get_parent() as CharacterController
	for child in get_children():
		if child is CharacterState:
			_states[child.name] = child
			child.controller = controller
			child.state_machine = self

	if _states.has(initial_state_name):
		current_state = _states[initial_state_name]
		current_state.enter("")
	else:
		push_error("CharacterStateMachine._ready: initial_state_name: '%s' ain't a valid state my dude. \
			Name must match the name of a child node of the StateMachine." % initial_state_name)
	DebugDisplay.watch("State", func(): return current_state.name)


func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func transition_to(state_name: String) -> void:
	if not _states.has(state_name):
		push_error("CharacterStateMachine.transition_to: no state named '%s'." % state_name)
		return
	if current_state == _states[state_name]:
		return

	var previous_name := current_state.name if current_state else StringName("")
	if current_state:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter(previous_name)


func get_state_name() -> String:
	return current_state.name if current_state else StringName("")


func is_in_state(state_name: String) -> bool:
	return get_state_name() == state_name
