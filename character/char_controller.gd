extends CharacterBody2D
class_name CharacterController

@export_category("Ground Movement")
## Max speed of the player in pixels/sec
@export var max_speed := 150.0
## Rate at which the char accelerates in x when input is provided. in pixels/sec^2
@export var acceleration := 700.0
## Rate at which the char decelerates in x when no input is provided. (Sliding stop.) in pixels/sec^2
@export var deceleration := 700.0
## Rate at which the character decelerates in x when given opposite input. in pixels/sec^2
@export var turn_acceleration := 1200.0

@export_category("Air Movement")
## Rate at which the char accelerates in x in the air when input is provided. in pixels/sec^2
@export var air_acceleration := 400.0
## Rate at which the char decelerates in x when given opposite input in air. in pixels/sec^2
@export var air_turn_acceleration := 800.0

@export_category("Jump Tuning")
## Impulse applied immediately upon jumping.
@export var min_jump_force: float = 250.0
## Upward force added per second while holding jump button.
@export var jump_hold_force: float = 500.0
## Hold length in seconds to achieve maximum jump height.
@export var jump_hold_time_seconds: float = 0.3

@export_category("Assists")
## When you fall off an edge, you can still input a jump for this many seconds.
@export var coyote_time: float = 0.15
## When landing, you can input a jump this many seconds before you land to jump immediately.
@export var jump_buffer_time: float = 0.15

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: CharacterStateMachine = $StateMachine

var move_input: float = 0.0
var is_ducking: bool = false

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_read_input()

	state_machine.physics_update(delta)
	_check_jump_trigger()

	move_and_slide()



func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if _buffer_timer > 0.0:
		_buffer_timer -= delta


func _read_input() -> void:
	move_input = Input.get_axis("move_left", "move_right")
	is_ducking = Input.is_action_pressed("duck")

	if Input.is_action_just_pressed("jump"):
		_buffer_timer = jump_buffer_time


func _check_jump_trigger() -> void:
	if state_machine.is_in_state("jump"):
		return
	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		state_machine.transition_to("jump")


func consume_jump() -> void:
	_coyote_timer = 0.0
	_buffer_timer = 0.0




# --- HELPERS ---

# TODO: Probably move these to grounded and air state?
func apply_ground_movement(delta: float) -> void:
	if move_input != 0.0:
		if move_input * velocity.x > 0:
			velocity.x = move_toward(velocity.x, move_input * max_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, move_input * max_speed, turn_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func apply_air_movement(delta: float) -> void:
	if move_input != 0.0:
		if move_input * velocity.x > 0:
			velocity.x = move_toward(velocity.x, move_input * max_speed, air_acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, move_input * max_speed, air_turn_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


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
