extends Node

# Now it's a stack idk lol should've made this an integer
var _stack: Array[StringName] = []

var player: CharacterController = null

func request_pause(reason: StringName) -> void:
	if player: player.set_physics_process(false)
	if not _stack.has(reason):
		_stack.append(reason)
	get_tree().paused = true


func release_pause(reason: StringName) -> void:
	_stack.erase(reason)
	var paused = not _stack.is_empty()
	get_tree().paused = paused
	if player:
		# Prevents the "jump when exit" thing by ignoring input for a frame.
		await get_tree().physics_frame
		await get_tree().physics_frame
		player.set_physics_process(not paused)


func is_paused_for(reason: StringName) -> bool:
	return _stack.has(reason)


func is_topmost(reason: StringName) -> bool:
	return _stack.size() > 0 and _stack[-1] == reason


func has_any_pause() -> bool:
	return not _stack.is_empty()
