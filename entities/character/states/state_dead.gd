class_name StateDead
extends CharacterState

@export var death_duration: float = 1.2
@export var death_effect: ImpactEffect

var _is_current: bool = false


func enter(_previous_state_name: String, _params: Dictionary = {}) -> void:
	_is_current = true
	controller.velocity = Vector2.ZERO
	controller.animated_sprite_2d.play("death")
	FX.play(death_effect, controller.global_position)
	_run_death_timer()


func exit() -> void:
	_is_current = false


func _run_death_timer() -> void:
	await get_tree().create_timer(death_duration).timeout

	if not _is_current:
		return

	controller.death_finished.emit()
