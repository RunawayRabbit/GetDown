class_name StateDuck
extends StateGrounded

var _charge_timer := 0.0
var _is_charged := false

@onready var standing_collider: CollisionShape2D = $"../../StandingCollider"
@onready var ducking_collider: CollisionShape2D = $"../../DuckingCollider"


func _ready() -> void:
	standing_collider.disabled = false
	ducking_collider.disabled = true


func enter(_previous_state_name: String, _params: Dictionary = {}) -> void:
	_charge_timer = 0.0
	_is_charged = false
	DebugDisplay.watch("Jump Charge", func(): return _is_charged)
	standing_collider.disabled = true
	ducking_collider.disabled = false


func exit() -> void:
	DebugDisplay.remove_watch("Jump Charge")
	standing_collider.disabled = false
	ducking_collider.disabled = true


func physics_update(delta: float) -> void:
	
	controller.apply_movement(delta, max_speed, acceleration, turn_acceleration, deceleration)

	if controller.move_input != 0.0: _charge_timer = 0.0
	controller.update_facing()

	controller.velocity += controller.get_gravity() * delta


	if not controller.is_on_floor():
		state_machine.transition_to("fall")
		return

	if not controller.is_ducking and _can_stand():
		state_machine.transition_to("run" if absf(controller.velocity.x) > 10.0 else "idle")
		return

	if not _is_charged:
		_charge_timer += delta
		if _charge_timer >= controller.charge_jump_time:
			_is_charged = true

	controller.play_animation(_current_animation())


func _can_stand() -> bool:
	var result = controller.shapecast(standing_collider.shape, standing_collider.transform)
	return result.is_empty()


func get_jump_params() -> Dictionary:
	if _is_charged:
		return {"impulse": controller.charge_jump_impulse}
	return {}


func _current_animation() -> String:
	return "duck_charged" if _is_charged else "duck"
