extends Node2D


@export var loop_mode: LoopMode = LoopMode.PING_PONG
## Time in seconds to complete one direction/loop
@export var move_duration: float = 2.0
## Pause duration at endpoints (Ignored if CLOSED_LOOP has no pause needed)
@export var pause_duration: float = 1.0
## Easing type for acceleration/deceleration
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
## True: we can jump up through the platform, False: we hit our hed. =(
@export var one_way_collision:bool = false

@onready var path_2d: Path2D = $Path2D
@onready var collision_shape_2d: CollisionShape2D = $AnimatableBody2D/CollisionShape2D
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D

enum LoopMode { PING_PONG, RESTART, CLOSED_LOOP }


func _ready() -> void:
	start_platform_loop()
	collision_shape_2d.one_way_collision = one_way_collision


func start_platform_loop() -> void:
	var curve: Curve2D = path_2d.curve
	if curve == null or curve.point_count < 2:
		push_warning("Path2D requires at least 2 points to animate.")
		return

	var total_length: float = curve.get_baked_length()
	if total_length == 0.0:
		return

	# Calculate progress_ratio (0.0 to 1.0) for each point on the curve
	var point_ratios: Array[float] = []
	for i in range(curve.point_count):
		# 1. Fetch the local position of point i
		var point_pos: Vector2 = curve.get_point_position(i)
		# 2. Get the pixel distance along the curve to that position
		var offset: float = curve.get_closest_offset(point_pos)
		# 3. Convert distance into a 0.0 -> 1.0 ratio
		point_ratios.append(offset / total_length)

	var tween: Tween = create_tween().set_loops()

	match loop_mode:
		LoopMode.PING_PONG:
			# Forward
			_add_sequence_to_tween(tween, point_ratios)
			# Backward
			var reverse_ratios: Array[float] = point_ratios.duplicate()
			reverse_ratios.reverse()
			_add_sequence_to_tween(tween, reverse_ratios)

		LoopMode.RESTART:
			_add_sequence_to_tween(tween, point_ratios)
			tween.tween_callback(func(): path_follow.progress_ratio = 0.0)

		LoopMode.CLOSED_LOOP:
			_add_sequence_to_tween(tween, point_ratios)
			tween.tween_callback(func(): path_follow.progress_ratio = 0.0)

func _add_sequence_to_tween(tween: Tween, ratios: Array[float]) -> void:
	for i in range(1, ratios.size()):
		var target_ratio: float = ratios[i]
		
		tween.tween_property(path_follow, "progress_ratio", target_ratio, move_duration)\
			.set_trans(transition_type)\
			.set_ease(ease_type)
			
		if pause_duration > 0.0:
			tween.tween_interval(pause_duration)
