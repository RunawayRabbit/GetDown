extends StateAir
class_name StateJump

var _hold_timer := 0.0

func enter(_previous_state_name: String) -> void:
	controller.velocity.y = -controller.min_jump_force
	_hold_timer = 0.0
	controller.consume_jump()

func _apply_vertical(delta: float) -> void:
	var still_holding := Input.is_action_pressed("jump") and _hold_timer < controller.jump_hold_time_seconds
	if still_holding:
		_hold_timer += delta
		controller.velocity += controller.get_gravity() * 0.3 * delta
		controller.velocity.y -= controller.jump_hold_force * delta
	else:
		controller.velocity += controller.get_gravity() * delta

func _get_animation() -> String:
	return "jump"

func _check_air_transition() -> void:
	if controller.velocity.y >= 0.0:
		state_machine.transition_to("fall")
