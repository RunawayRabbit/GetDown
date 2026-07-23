extends CharacterState
class_name StateAir

## Max speed of the player in pixels/sec
@export var max_speed := 150.0
## Rate at which the char accelerates in x when input is provided. in pixels/sec^2
@export var acceleration := 400.0
## Rate at which the char decelerates in x when no input is provided. (Sliding stop.) in pixels/sec^2
@export var deceleration := 300.0
## Rate at which the character decelerates in x when given opposite input. in pixels/sec^2
@export var turn_acceleration := 800.0


func physics_update(delta: float) -> void:
	_apply_vertical(delta)
	controller.apply_movement(delta, max_speed, acceleration, turn_acceleration, deceleration)
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
