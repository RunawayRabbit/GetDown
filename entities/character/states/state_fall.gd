extends StateAir
class_name StateFall

func _apply_vertical(delta: float) -> void:
	controller.velocity += controller.get_gravity() * delta

func _get_animation() -> String:
	return "fall"
