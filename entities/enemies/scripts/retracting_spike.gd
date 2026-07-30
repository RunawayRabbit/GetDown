extends Hazard
class_name RetractingSpike

## Safe period
@export var retracted_duration: float = 1.5
## Telegraph window before extending
@export var warning_duration: float = 0.4
## How long it stays out for
@export var extended_duration: float = 1.0
## Delay before this spike's very first cycle for staggering them.
@export var start_offset: float = 0.0

@export var extend_effect: ImpactEffect
@export var retract_effect: ImpactEffect

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super._ready()
	monitoring = false
	_run_cycle()

# Again, how the *fuck* is this not something the engine does?!
func get_animation_total_time(sprite_frames: SpriteFrames, anim_name: StringName) -> float:
	if not sprite_frames.has_animation(anim_name):
		return 0.0
		
	var fps = sprite_frames.get_animation_speed(anim_name)
	if fps <= 0:
		return 0.0
		
	var frame_count = sprite_frames.get_frame_count(anim_name)
	var total_duration_units = 0.0
	
	for i in range(frame_count):
		total_duration_units += sprite_frames.get_frame_duration(anim_name, i)
		
	return total_duration_units / fps


func _run_cycle() -> void:
	if start_offset > 0.0:
		await get_tree().create_timer(start_offset).timeout

	while is_inside_tree():
		await get_tree().create_timer(retracted_duration).timeout

		anim.play("warning_start")
		var start_duration := get_animation_total_time(anim.sprite_frames, "warning_start")
		if start_duration < warning_duration:
			await anim.animation_finished
			print(warning_duration - start_duration)
			await get_tree().create_timer(warning_duration - start_duration).timeout
		else:
			await get_tree().create_timer(warning_duration).timeout

		anim.play("extend")
		FX.play(extend_effect, global_position)
		monitoring = true

		await get_tree().create_timer(extended_duration).timeout

		monitoring = false
		anim.play("retract")
		FX.play(retract_effect, global_position)
