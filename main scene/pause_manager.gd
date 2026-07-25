extends Node

# TODO: Do we REALLY not have set??!?!!
var _reasons: Dictionary = {} # (StringName) -> true


func request_pause(reason: StringName) -> void:
	_reasons[reason] = true
	get_tree().paused = true


func release_pause(reason: StringName) -> void:
	_reasons.erase(reason)
	get_tree().paused = not _reasons.is_empty()


func is_paused_for(reason: StringName) -> bool:
	return _reasons.has(reason)


func is_blocked_by_other(reason: StringName) -> bool:
	for r in _reasons:
		if r != reason:
			return true
	return false
