extends CharacterState
class_name StateGrounded

func physics_update(delta: float) -> void:
	controller.apply_ground_movement(delta)
	controller.update_facing()

	if not controller.is_on_floor():
		state_machine.transition_to("fall")
		return

	if controller.is_ducking:
		controller.play_animation("duck")
	else:
		controller.play_animation("run" if _is_moving() else "idle")

	if _is_moving():
		state_machine.transition_to("run")
	else:
		state_machine.transition_to("idle")

func _is_moving() -> bool:
	return absf(controller.velocity.x) > 10.0
