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
@export var min_jump_force : float = 250.0
## Upward force added per second while holding jump button.
@export var jump_hold_force : float = 500.0
## Hold length in seconds to achieve maximum jump height.
@export var jump_hold_time_seconds : float = 0.3

@export_category("Assists")
## When you fall off an edge, you can still input a jump for this many seconds.
@export var coyote_time : float = 0.15
## When landing, you can input a jump this many seconds before you land to jump immediately.
@export var jump_buffer_time : float = 0.15

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

enum PlayerState { IDLE, WALK, JUMP, FALL }
var _state := PlayerState.IDLE

var _coyote_timer : float = 0.0
var _buffer_timer : float = 0.0
var _jump_hold_timer : float = 0.0
var _is_jumping : bool = false
var _move_input : float = 0.0
var _is_ducking : bool = false

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_process_input(delta)
	
	_update_state()
	_do_movement(delta)
	
	move_and_slide()
	_update_sprite()

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if _buffer_timer > 0.0:
		_buffer_timer -= delta

func _process_input(_delta: float) -> void:
	_move_input = Input.get_axis("move_left", "move_right")
	_is_ducking = Input.is_action_pressed("duck")

	if Input.is_action_just_pressed("jump"):
		_buffer_timer = jump_buffer_time

	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		_start_jump()

	if Input.is_action_just_released("jump") or _jump_hold_timer >= jump_hold_time_seconds:
		_is_jumping = false

func _start_jump() -> void:
	velocity.y = -min_jump_force
	_coyote_timer = 0.0
	_buffer_timer = 0.0
	_jump_hold_timer = 0.0
	_is_jumping = true
	_state = PlayerState.JUMP

func _update_state() -> void:
	if is_on_floor():
		if abs(velocity.x) > 10.0:
			_state = PlayerState.WALK
		else:
			_state = PlayerState.IDLE
	else:
		if velocity.y < 0.0:
			_state = PlayerState.JUMP
		else:
			_state = PlayerState.FALL

func _do_movement(delta: float) -> void:
	match _state:
		PlayerState.IDLE, PlayerState.WALK:
			_do_ground_movement(delta)
		PlayerState.JUMP, PlayerState.FALL:
			_do_air_movement(delta)

func _do_ground_movement(delta: float) -> void:
	if _move_input != 0.0:
		if _move_input * velocity.x > 0:
			velocity.x = move_toward(velocity.x, _move_input * max_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, _move_input * max_speed, turn_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _do_air_movement(delta: float) -> void:
	var grav := get_gravity()

	if _is_jumping and Input.is_action_pressed("jump"):
		_jump_hold_timer += delta
		velocity += (grav * 0.3) * delta
		velocity.y -= jump_hold_force * delta
	else:
		velocity += grav * delta

	if _move_input != 0.0:
		if _move_input * velocity.x > 0:
			velocity.x = move_toward(velocity.x, _move_input * max_speed, air_acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, _move_input * max_speed, air_turn_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _update_sprite() -> void:
	if not animated_sprite_2d:
		return
	
	if velocity.x < 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = true
		
	match _state:
		PlayerState.JUMP:
			# Godot will "loop" if I tell it to play on every frame.
			# Hacky way to prevent this..
			if animated_sprite_2d.frame_progress < 1.0:
				animated_sprite_2d.play("jump")
		PlayerState.FALL:
			if animated_sprite_2d.sprite_frames.has_animation("fall"):
				animated_sprite_2d.play("fall")
			else:
				animated_sprite_2d.play("jump")
		PlayerState.WALK:
			if _is_ducking:
				animated_sprite_2d.play("duck")
			else:
				animated_sprite_2d.play("run")
		PlayerState.IDLE:
			if _is_ducking:
				animated_sprite_2d.play("duck")
			else:
				animated_sprite_2d.play("idle")
