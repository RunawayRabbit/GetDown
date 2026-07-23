extends CharacterState
class_name StateWall

## Duration we hold duck for in order to trigger a jump.
@export var flick_charge_time: float = 1.0
## Vertical impulse of a wall jump, same units as min_jump_force.
@export var wall_jump_impulse: float = 220.0

var _grabbed_dir: int = 1
var _charge_timer:float = 0.0


func enter(_previous_state_name: String, _payload: Dictionary = {}) -> void:
	_grabbed_dir = controller.facing_dir
	controller.velocity = Vector2.ZERO
	controller.play_animation("wall_grab")

	#TODO: Does wall grabbing give you a new float?
	#controller.refill_double_jump()

func exit() -> void:
	controller.wall_released_this_frame = true

func physics_update(_delta: float) -> void:
	controller.velocity = Vector2.ZERO

	if controller.is_on_floor():
		state_machine.transition_to("run" if absf(controller.velocity.x) > 10.0 else "idle")
		return

	if not controller.has_wall_in_front(_grabbed_dir):
		state_machine.transition_to("fall")
		return


	if controller.is_attack_pressed() or controller.move_input * _grabbed_dir < -0.1:
		state_machine.transition_to("fall")
		return


func get_jump_params() -> Dictionary:
	return {
		"impulse": wall_jump_impulse
	}
