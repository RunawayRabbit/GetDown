
class_name StateHover
extends StateAir

var _timer := 0.0
@export var curve:Curve


## Duration of the dip-to-ZOOP in seconds.
@export var time: float = 1.2



func enter(_previous_state_name: String, _params: Dictionary = {}) -> void:
	_timer = 0.0
	controller.velocity.y = 0.0
	controller.consume_double_jump()

func exit() -> void:
	DebugDisplay.remove_watch("Hover Weight")
	


func _apply_vertical(delta: float) -> void:
	var grav = controller.get_gravity()

	DebugDisplay.watch("Hover Weight", func(): return curve.sample(_timer))
	var hover_force: float = grav.y + curve.sample(_timer)
	controller.velocity += grav * delta
	controller.velocity.y -= hover_force * delta
	_timer += delta


func _get_animation() -> String:
		return "hover"


func _check_air_transition() -> void:
	if _timer >= curve.max_domain:
		state_machine.transition_to("fall")
