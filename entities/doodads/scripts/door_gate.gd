extends Node2D
class_name DoorGate


enum State { OPEN, HALF_BLOCKED, CLOSED }

@export var time_to_open: float = 2.0
@export var time_to_close: float = 10.0

var ducking_shape: Shape2D = preload("uid://p2p6cilw8jlg")
@export var gap_margin: float = 8.0

## Plays once when it closes.
@export var seal_effect: ImpactEffect
## Plays repeatedly during closing "phase 1".
@export var tick_effect: ImpactEffect
@export var tick_interval: float = 0.6

signal closing_progress(t: float)

@onready var body: AnimatableBody2D = $Body
@onready var clearance_zone: Area2D = $ClearanceZone
@onready var open_position: Marker2D = $Open
@onready var closed_position: Marker2D = $Closed

var state: State = State.OPEN

var _minimal_gap_position: Vector2
var _phase_1_duration: float
var _phase_2_duration: float

var _tween: Tween = null


func _ready() -> void:
	set_physics_process(false)
	body.position = open_position.position

	if closed_position.position.y <= open_position.position.y:
		push_warning("%s: DoorGate assumes doors close top-to-bottom." % name)

	_precompute_minimal_gap()


func _precompute_minimal_gap() -> void:
	var required_gap := _get_shape_height(ducking_shape) + gap_margin
	var total_drop := closed_position.position.y - open_position.position.y

	if total_drop > 0.0 and required_gap >= total_drop:
		push_warning("%s: Is this door even big enough for the player to duck through?" % name)

	var minimal_gap_y := closed_position.position.y - required_gap
	minimal_gap_y = clamp(minimal_gap_y, open_position.position.y, closed_position.position.y)

	_minimal_gap_position = Vector2(open_position.position.x, minimal_gap_y)

	var ratio := 0.0
	if total_drop != 0.0:
		ratio = (minimal_gap_y - open_position.position.y) / total_drop

	_phase_1_duration = time_to_close * ratio
	_phase_2_duration = time_to_close * (1.0 - ratio)


func _get_shape_height(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return shape.size.y
	if shape is CapsuleShape2D:
		return shape.height + shape.radius * 2.0
	if shape is CircleShape2D:
		return shape.radius * 2.0

	push_error("%s: ducking_shape is a %s - DoorGate doesn't know how to measure its height. Add a case to _get_shape_height()." % [name, shape.get_class() if shape else "null"])
	return 0.0


func snap_open() -> void:
	_kill_tween()
	set_physics_process(false)
	state = State.OPEN
	body.position = open_position.position


func snap_closed() -> void:
	_kill_tween()
	set_physics_process(false)
	state = State.CLOSED
	body.position = closed_position.position


func open() -> void:
	if state == State.OPEN:
		return

	set_physics_process(false) # Cancel any pending seal-wait from a mid-close reopen.
	state = State.OPEN
	_tween_to(open_position.position, time_to_open)


func close() -> void:
	if state == State.CLOSED or state == State.HALF_BLOCKED:
		return

	state = State.HALF_BLOCKED
	_tween_to(_minimal_gap_position, _phase_1_duration)
	_run_closing_affordance()

	# Timer-based, not tween.finished-based - a reopen mid-phase-1 kills this
	# tween without ever firing its finished signal, and this wait needs to
	# resolve regardless so the state check below actually runs.
	await get_tree().create_timer(_phase_1_duration).timeout

	if state != State.HALF_BLOCKED:
		return # Reopened while phase 1 was still playing.

	set_physics_process(true) # Poll clearance_zone until it's safe to finish sealing.


func _run_closing_affordance() -> void:
	var elapsed := 0.0
	while state == State.HALF_BLOCKED and elapsed < _phase_1_duration:
		var t := elapsed / _phase_1_duration if _phase_1_duration > 0.0 else 1.0
		closing_progress.emit(t)
		FX.play(tick_effect, body.global_position)
		await get_tree().create_timer(tick_interval).timeout
		elapsed += tick_interval


func _physics_process(_delta: float) -> void:
	if state != State.HALF_BLOCKED:
		set_physics_process(false)
		return

	if not clearance_zone.get_overlapping_bodies().is_empty():
		return # Still occupied - try again next physics frame.

	state = State.CLOSED
	_tween_to(closed_position.position, _phase_2_duration)
	FX.play(seal_effect, body.global_position)
	set_physics_process(false)


func _tween_to(target: Vector2, t: float) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(body, "position", target, t)


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
