extends Node

# Now it's a stack idk lol should've made this an integer
var _stack: Array[StringName] = []


func request_pause(reason: StringName) -> void:
	if not _stack.has(reason):
		_stack.append(reason)
	get_tree().paused = true


func release_pause(reason: StringName) -> void:
	_stack.erase(reason)
	get_tree().paused = not _stack.is_empty()


func is_paused_for(reason: StringName) -> bool:
	return _stack.has(reason)


func is_topmost(reason: StringName) -> bool:
	return _stack.size() > 0 and _stack[-1] == reason


func has_any_pause() -> bool:
	return not _stack.is_empty()
