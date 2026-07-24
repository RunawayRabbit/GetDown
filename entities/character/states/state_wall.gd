extends CharacterState
class_name StateWall

@export_category("Wall Flick")
## Duration we hold duck for in order to trigger a jump.
@export var flick_charge_time: float = 1.0
## Vertical impulse of a wall jump, same units as min_jump_force.
@export var wall_jump_impulse: float = 220.0


var _grabbed_dir: int = 1
var _charge_timer:float = 0.0
var _is_charged: bool = false


func enter(_previous_state_name: String, _payload: Dictionary = {}) -> void:
	_grabbed_dir = controller.facing_dir
	_charge_timer = 0.0
	_is_charged = false
	controller.velocity = Vector2.ZERO
	#controller.refill_double_jump()

	if _payload.has("contact_point"):
		var beak_offset := controller.get_beak_offset(_grabbed_dir)
		controller.global_position.x = _payload["contact_point"].x - beak_offset.x


func physics_update(delta: float) -> void:
	controller.velocity = Vector2.ZERO
	
	if controller.is_on_floor():
		state_machine.transition_to("run" if absf(controller.velocity.x) > 10.0 else "idle")
		return
 
	if not controller.has_wall_in_front(_grabbed_dir):
		state_machine.transition_to("fall")
		return
 
	# Push away from the grabbed wall to let go early.
	if controller.move_input * _grabbed_dir < -0.1:
		state_machine.transition_to("fall")
		return
 
	# Attack lets go
	if controller.attack_button_went_down:
		state_machine.transition_to("fall")
		return
 
	if _is_charged:
		controller.play_animation("flick_charged")
		if not controller.is_ducking:
			state_machine.transition_to("jump", get_jump_params())
		return
 
	if controller.is_ducking:
		_charge_timer += delta
		if _charge_timer >= flick_charge_time:
			_is_charged = true
	else:
		_charge_timer = 0.0

	controller.scrub_animation("flick_charging", _charge_timer / flick_charge_time)


func get_jump_params() -> Dictionary:
	return {
		"impulse": wall_jump_impulse,
		"animation" : "flick"
	}
