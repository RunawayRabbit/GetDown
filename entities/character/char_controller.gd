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


@export_category("Attacking")
## How much we hinder the player's max speed while they are mid-attack.
@export var attack_movement_penalty: float = 0.4
## You can input an attack this many seconds before the cooldown is up to queue it.
@export var attack_buffer_time: float = 0.2


@export_category("Wall Grab")
## Size of a single sprite frame, in pixels. Used to convert texture-space
## anchor points (like beak_anchor) into local space relative to this node.
@export var sprite_frame_size: Vector2 = Vector2(48, 48)
## Beak tip position in texture space, (0,0) = top-left of the frame. Used to
## snap the player's position so the beak lands exactly on the wall on grab.
@export var beak_anchor: Vector2 = Vector2(0, 25)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ducking_collider: CollisionShape2D = $DuckingCollider
@onready var standing_collider: CollisionShape2D = $StandingCollider
@onready var state_machine: CharacterStateMachine = $StateMachine
@onready var beak_attack: BeakAttack = $BeakAttack
@onready var hitbox: Area2D = $Hitbox


var move_input: float = 0.0
var is_ducking: bool = false
var _can_hover_jump: bool = false
var _jump_button_went_down: bool = false
var attack_button_went_down: bool = false
var facing_dir:int = 1


var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _attack_lock_timer: float = 0.0
var _attack_buffer_timer: float = 0.0


func _ready() -> void:
	DebugDisplay.watch("Has Wall", func(): return has_wall_in_front(facing_dir))

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_read_input()

	state_machine.physics_update(delta)
	_check_jump_trigger()
	_force_duck()
	
	#TODO: Janky and inelegant.
	var attack_pressed_for_beak := attack_button_went_down
	if state_machine.is_in_state("wall") or _check_wall_grab_trigger():
		attack_pressed_for_beak = false
	beak_attack.physics_update(delta, attack_pressed_for_beak)

	move_and_slide()


func _update_timers(delta: float) -> void:
	#TODO: I know it's a game jam but holy fuck these timers gettin out of control
	# Really should be doing timestamps holy fuck
	if is_on_floor():
		_coyote_timer = coyote_time
		_can_hover_jump = true
	else:
		_coyote_timer -= delta

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
	
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer -= delta
		
	if _attack_lock_timer > 0.0:
		_attack_lock_timer -= delta
	
func _read_input() -> void:
	move_input = Input.get_axis("move_left", "move_right")
	is_ducking = Input.is_action_pressed("duck")

	attack_button_went_down = Input.is_action_just_pressed("attack")
	if attack_button_went_down:
		_attack_buffer_timer = attack_buffer_time

	_jump_button_went_down = Input.is_action_just_pressed("jump")
	if _jump_button_went_down:
		_jump_buffer_timer = jump_buffer_time


func _check_jump_trigger() -> void:
	# TODO: Raycast/shapecast down to see if we're nearing the floor.
	# Avoid hovering if we are in 
	if state_machine.is_in_state("hover"):
		return

	# Jump is ignored entirely while wall-grabbing right now.
	if state_machine.is_in_state("wall"):
		return
 
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		var params := state_machine.current_state.get_jump_params()
		state_machine.transition_to("jump", params)
		return
 
	if _can_hover_jump and not is_on_floor() and _jump_button_went_down:
		state_machine.transition_to("hover")


func _force_duck() -> void:
	if not shapecast(standing_collider.shape, standing_collider.transform).is_empty() and \
	   shapecast(ducking_collider.shape, ducking_collider.transform).is_empty():
		state_machine.transition_to("duck")


func _check_wall_grab_trigger() -> bool:
	if is_on_floor():
		return false
	if not beak_attack.is_active():
		return false
	var hit := probe_wall(facing_dir)
	if hit.is_empty():
		return false
	beak_attack.cancel()
	state_machine.transition_to("wall", {"contact_point": hit["position"]})
	return true


func probe_wall(dir: int) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var origin := global_position + get_beak_offset(dir)
	var target := origin + Vector2(beak_attack.get_hitbox_offset() * dir, 0.0)

	var query := PhysicsRayQueryParameters2D.create(origin, target)
	# NOTE: Hard-coded because the engine REALLY isn't good at naming collision layers
	query.collision_mask = 1 << 2
	query.exclude = [get_rid()]

	return space_state.intersect_ray(query)


func has_wall_in_front(dir: int) -> bool:
	return not probe_wall(dir).is_empty()


func get_beak_offset(dir: int) -> Vector2:
	var local := beak_anchor - sprite_frame_size / 2.0
	local.x *= -dir
	return local


func consume_jump() -> void:
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func consume_hover_jump() -> void:
	_can_hover_jump = false


func apply_movement(delta: float, max_speed:float, acceleration:float,
	 				turn_acceleration:float, deceleration:float) -> void:
	var speed := max_speed * (attack_movement_penalty if is_attacking() else 1.0)
	if move_input != 0.0:
		if move_input * velocity.x > 0:
			velocity.x = move_toward(velocity.x, move_input * speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, move_input * speed, turn_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func shapecast(shape:Shape2D, trans:Transform2D, mask:int = collision_mask, margin: float = 0.0) -> Array[Dictionary]:
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = transform * trans
	query.collision_mask = mask
	query.exclude = [get_rid()]
	query.margin = margin
	
	var result = space_state.intersect_shape(query)
	return result


func update_facing() -> void:
	if not animated_sprite_2d:
		return
	if velocity.x < 0:
		facing_dir = -1
		animated_sprite_2d.flip_h = false
	elif velocity.x > 0:
		facing_dir = 1
		animated_sprite_2d.flip_h = true


func is_attacking() -> bool:
	return _attack_lock_timer > 0.0


func is_attack_pressed() -> bool:
	return attack_button_went_down


func play_animation(anim_name: String) -> void:
	if is_attacking():
		return
	_play_animation_internal(anim_name)
 
 
func begin_attack_lock(duration: float) -> void:
	_attack_lock_timer = duration
 
 
func clear_attack_lock() -> void:
	_attack_lock_timer = 0.0
 
 
func force_play_animation(anim_name: String) -> void:
	_play_animation_internal(anim_name)
 
 
func scrub_animation(anim_name: String, progress: float) -> void:
	if is_attacking():
		return
	if not animated_sprite_2d or not animated_sprite_2d.sprite_frames:
		return
	if not animated_sprite_2d.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
	animated_sprite_2d.pause()
	var frame_count := animated_sprite_2d.sprite_frames.get_frame_count(anim_name)
	animated_sprite_2d.frame = clampi(int(clampf(progress, 0.0, 1.0) * frame_count), 0, frame_count - 1)
 
 
func _play_animation_internal(anim_name: String) -> void:
	if not animated_sprite_2d:
		return
	if animated_sprite_2d.sprite_frames and not animated_sprite_2d.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
