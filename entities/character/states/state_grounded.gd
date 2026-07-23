extends CharacterState
class_name StateGrounded

## Max speed of the player in pixels/sec
@export var max_speed := 150.0
## Rate at which the char accelerates in x when input is provided. in pixels/sec^2
@export var acceleration := 700.0
## Rate at which the char decelerates in x when no input is provided. (Sliding stop.) in pixels/sec^2
@export var deceleration := 700.0
## Rate at which the character decelerates in x when given opposite input. in pixels/sec^2
@export var turn_acceleration := 1200.0



func physics_update(delta: float) -> void:
	if controller.is_ducking:
		state_machine.transition_to("duck")
		return
 	
	controller.apply_movement(delta, max_speed, acceleration, turn_acceleration, deceleration)
	
	controller.update_facing()
 
	if not controller.is_on_floor():
		state_machine.transition_to("fall")
		return
 
	controller.play_animation("run" if _is_moving() else "idle")


	if _is_moving():
		state_machine.transition_to("run")
	else:
		state_machine.transition_to("idle")

func _is_moving() -> bool:
	return absf(controller.velocity.x) > 10.0
