@tool
extends Node2D


@export var loop_mode: LoopMode = LoopMode.PING_PONG
## Time in seconds to complete one direction/loop
@export var move_duration: float = 2.0
## Pause duration at endpoints (Ignored if CLOSED_LOOP has no pause needed)
@export var pause_duration: float = 1.0
## Easing type for acceleration/deceleration
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
## True: we can jump up through the platform, False: we hit our head. =(
@export var one_way_collision: bool = false

## Editor preview
@export var show_path_platforms: bool = true
@export var editor_platform_color: Color = Color(0.2, 0.8, 1.0, 0.25)

@onready var sprite_2d: Sprite2D = $AnimatableBody2D/Sprite2D

@onready var path_2d: Path2D = $Path2D
@onready var collision_shape_2d: CollisionShape2D = $AnimatableBody2D/CollisionShape2D
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D


enum LoopMode { PING_PONG, RESTART, CLOSED_LOOP }


func _ready() -> void:
	if not Engine.is_editor_hint():
		start_platform_loop()
		collision_shape_2d.one_way_collision = one_way_collision
		sprite_2d.scale = collision_shape_2d.shape.get_rect().size


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if !Engine.is_editor_hint():
		return

	if !show_path_platforms:
		return

	if !is_instance_valid(path_2d):
		return

	if !is_instance_valid(collision_shape_2d):
		return

	var shape := collision_shape_2d.shape

	if shape == null:
		return

	if !(shape is RectangleShape2D):
		return

	var platform_size: Vector2 = shape.size
	var offset: Vector2 = collision_shape_2d.position

	var ratios := get_path_stop_ratios()

	for ratio in ratios:
		var distance := ratio * path_2d.curve.get_baked_length()
		var point := path_2d.curve.sample_baked(distance)

		# Convert Path2D local space into this Node2D's local space
		var draw_position := path_2d.position + offset + point

		var rect := Rect2(
			draw_position - platform_size * 0.5,
			platform_size
		)

		draw_rect(rect, editor_platform_color, true)
		draw_rect(rect, editor_platform_color.lightened(0.5), false, 2.0)


func get_path_stop_ratios() -> Array[float]:
	var ratios: Array[float] = []

	if path_2d.curve == null:
		return ratios

	if path_2d.curve.point_count < 2:
		return ratios

	var total_length := path_2d.curve.get_baked_length()

	if total_length == 0:
		return ratios

	for i in range(path_2d.curve.point_count):
		var point_pos: Vector2 = path_2d.curve.get_point_position(i)
		var offset: float = path_2d.curve.get_closest_offset(point_pos)
		ratios.append(offset / total_length)

	return ratios


func start_platform_loop() -> void:
	var curve: Curve2D = path_2d.curve
	if curve == null or curve.point_count < 2:
		push_warning("Path2D requires at least 2 points to animate.")
		return

	var total_length: float = curve.get_baked_length()
	if total_length == 0.0:
		return

	var point_ratios: Array[float] = get_path_stop_ratios()

	var tween: Tween = create_tween().set_loops()

	match loop_mode:
		LoopMode.PING_PONG:
			_add_sequence_to_tween(tween, point_ratios)

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

		tween.tween_property(
			path_follow,
			"progress_ratio",
			target_ratio,
			move_duration
		)\
		.set_trans(transition_type)\
		.set_ease(ease_type)

		if pause_duration > 0.0:
			tween.tween_interval(pause_duration)
