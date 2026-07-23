extends CharacterBody2D
class_name CharacterController


# TODO: Impulse is fucky because of the weird non-linearity. Do I go all the way to my stupid
# barely working jump height math?
@export_category("Jump Tuning")
## Impulse applied immediately upon jumping.
@export var min_jump_force: float = 200.0
## Upward force added per second while holding jump button.
@export var jump_hold_force: float = 400.0
## Hold length in seconds to achieve maximum jump height.
@export var jump_hold_time_seconds: float = 0.3
## How long you must hold duck on the ground before the jump becomes charged.
@export var charge_jump_time: float = 0.8
## Impulse applied instead of min_jump_force when jumping out of a charged duck.
@export var charge_jump_impulse: float = 300.0


@export_category("Assists")
## When you fall off an edge, you can still input a jump for this many seconds.
@export var coyote_time: float = 0.15
## When landing, you can input a jump this many seconds before you land to jump immediately.
@export var jump_buffer_time: float = 0.15


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: CharacterStateMachine = $StateMachine
@onready var ducking_collider: CollisionShape2D = $DuckingCollider
@onready var standing_collider: CollisionShape2D = $StandingCollider


var move_input: float = 0.0
var is_ducking: bool = false
var _can_hover_jump: bool = false
var _jump_button_went_down: bool = false


var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_read_input()

	state_machine.physics_update(delta)
	_check_jump_trigger()
	_force_duck()

	move_and_slide()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_can_hover_jump = true
	else:
		_coyote_timer -= delta

	if _buffer_timer > 0.0:
		_buffer_timer -= delta

	
func _read_input() -> void:
	move_input = Input.get_axis("move_left", "move_right")
	is_ducking = Input.is_action_pressed("duck")

	_jump_button_went_down = Input.is_action_just_pressed("jump")
	if _jump_button_went_down:
		_buffer_timer = jump_buffer_time


func _check_jump_trigger() -> void:
	if state_machine.is_in_state("hover"):
		return
 
	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		var params := state_machine.current_state.get_jump_params()
		state_machine.transition_to("jump", params)
		return
 

	if _can_hover_jump and not is_on_floor() and _jump_button_went_down:
		state_machine.transition_to("hover")


func _force_duck() -> void:
	if not shapecast(standing_collider.shape, standing_collider.transform).is_empty() and \
	   shapecast(ducking_collider.shape, ducking_collider.transform).is_empty():
		state_machine.transition_to("duck")



func consume_jump() -> void:
	_coyote_timer = 0.0
	_buffer_timer = 0.0

func consume_double_jump() -> void:
	_can_hover_jump = false


# TODO: Probably move these to grounded and air state?
func apply_movement(delta: float, max_speed:float, acceleration:float,
	 				turn_acceleration:float, deceleration:float) -> void:
	if move_input != 0.0:
		if move_input * velocity.x > 0:
			velocity.x = move_toward(velocity.x, move_input * max_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, move_input * max_speed, turn_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)



func shapecast(shape:Shape2D, trans:Transform2D) -> Array[Dictionary]:
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = transform * trans
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	
	return space_state.intersect_shape(query)


func update_facing() -> void:
	if not animated_sprite_2d:
		return
	if velocity.x < 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = true


func play_animation(anim_name: String) -> void:
	if not animated_sprite_2d:
		return
	if animated_sprite_2d.sprite_frames and not animated_sprite_2d.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
