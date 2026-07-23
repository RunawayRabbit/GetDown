class_name StateDuck
extends StateGrounded

var _charge_timer := 0.0
var _is_charged := false


func enter(_previous_state_name: String, _params: Dictionary = {}) -> void:
	_charge_timer = 0.0
	_is_charged = false
	DebugDisplay.watch("Jump Charge", func(): return _is_charged)


func exit() -> void:
	DebugDisplay.remove_watch("Jump Charge")
	


func physics_update(delta: float) -> void:
	
	controller.apply_ground_friction(delta)
	#controller.apply_ground_movement(delta)
	controller.update_facing()

	if not controller.is_on_floor():
		state_machine.transition_to("fall")
		return

	if not controller.is_ducking:
		state_machine.transition_to("run" if absf(controller.velocity.x) > 10.0 else "idle")
		return

	if not _is_charged:
		_charge_timer += delta
		if _charge_timer >= controller.charge_jump_time:
			_is_charged = true

	controller.play_animation(_current_animation())


func get_jump_params() -> Dictionary:
	if _is_charged:
		return {"impulse": controller.charge_jump_impulse}
	return {}


func _current_animation() -> String:
	return "duck_charged" if _is_charged else "duck"
