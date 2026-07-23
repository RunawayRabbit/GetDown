extends CharacterState
class_name StateAir

func physics_update(delta: float) -> void:
	_apply_vertical(delta)
	controller.apply_air_movement(delta)
	controller.update_facing()
	controller.play_animation(_get_animation())

	if controller.is_on_floor():
		state_machine.transition_to("run" if absf(controller.velocity.x) > 10.0 else "idle")
		return

	_check_air_transition()

## Override: apply gravity / hold-force / whatever this state's vertical rule is.
## You may safely assume gravity doesn't change in this game. I think. =/
func _apply_vertical(_delta: float) -> void:
	pass

## Override: return the animation name to play this frame.
func _get_animation() -> String:
	return "fall"

## Override: transition to another airborne state if needed (e.g. Jump -> Fall).
func _check_air_transition() -> void:
	pass
