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


@export_category("Collision Shapes")
## Both the physics collider and the hurtbox swap together, driven from one
## place - keeps them from ever drifting out of sync, and replaces the old
## two-CollisionShape2D disable/enable dance that was causing the
## double-trigger: disabling one shape's owner while enabling a different
## one's inside the same physics step reads to Godot as a real exit
## followed by a real re-entry, even though you were continuously
## overlapping the whole time. Swapping .shape on one always-enabled node
## keeps that owner's identity stable across the change, so there's nothing
## for an overlapping Area2D to exit/re-enter over.
@export var standing_shape: Shape2D
@export var standing_offset: Vector2 = Vector2.ZERO
@export var ducking_shape: Shape2D
@export var ducking_offset: Vector2 = Vector2.ZERO


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collider: CollisionShape2D = $BodyCollider
@onready var hurtbox_collider: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var state_machine: CharacterStateMachine = $StateMachine
@onready var beak_attack: BeakAttack = $BeakAttack
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var remote_transform_2d: RemoteTransform2D = $RemoteTransform2D


var move_input: float = 0.0
var is_ducking: bool = false
## Tracks which shape is actually applied right now - distinct from
## is_ducking (raw input state) since this only changes when the state
## machine actually enters/exits the duck state, not every frame the
## button happens to be held.
var is_shape_ducked: bool = false
var _can_hover_jump: bool = false
var _jump_button_went_down: bool = false
var attack_button_went_down: bool = false
var facing_dir:int = 1


var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _attack_lock_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var wall_released_this_frame: bool = false


class Ability:
	const DUCK_JUMP: StringName = &"duck"
	const YOSHI_JUMP: StringName = &"yoshi"
	const PECK_CLIMB: StringName = &"peck"

var _abilities: Dictionary = {}

func has_ability(ability: StringName) -> bool:
	return _abilities.has(ability)

func add_ability(ability: StringName) -> void:
	prints("Adding ability", ability)
	_abilities[ability] = true

func remove_ability(ability: StringName) -> void:
	_abilities.erase(ability)


var cam:Cam
var game_manager:GameManager


func _ready() -> void:
	hurtbox.died.connect(_on_hurtbox_died)
	set_ducked_shape(false)


func _on_hurtbox_died() -> void:
	if game_manager:
		game_manager.player_died()


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

	wall_released_this_frame = false
	
func _read_input() -> void:
	move_input = Input.get_axis("move_left", "move_right")
	is_ducking = Input.is_action_pressed("duck")

	attack_button_went_down = Input.is_action_just_pressed("attack")
	if attack_button_went_down:
		_attack_buffer_timer = attack_buffer_time

	#TODO: BUG: "jump" often meaning "space" is also used by the dialogue manager.
	# Meaning we jump right after exiting a dialogue. Fun stuff. -.-
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
 
	if has_ability(Ability.YOSHI_JUMP) and _can_hover_jump and not is_on_floor() and _jump_button_went_down:
		state_machine.transition_to("hover")


func _force_duck() -> void:
	var standing_transform := Transform2D(0.0, standing_offset)
	var ducking_transform := Transform2D(0.0, ducking_offset)
	if not shapecast(standing_shape, standing_transform).is_empty() and \
	   shapecast(ducking_shape, ducking_transform).is_empty():
		state_machine.transition_to("duck")


## Swaps both the physics collider and the hurtbox to the standing or
## ducking shape together, so they can never disagree about the player's
## current size. Call this instead of touching either collider directly.
##
## standing_offset/ducking_offset are both measured relative to the
## character's own base (CharacterController's origin) - NOT relative to
## whatever parent each CollisionShape2D actually has. body_collider is a
## direct child so that's a 1:1 assignment, but hurtbox_collider's parent is
## Hurtbox, which may itself sit at a non-zero local position - so its
## offset has to be re-based into Hurtbox's own local space, or the two
## shapes will silently end up in different places despite sharing a
## "shared" offset value.
func set_ducked_shape(ducked: bool) -> void:
	if ducked == is_shape_ducked:
		return

	is_shape_ducked = ducked
	var shape := ducking_shape if ducked else standing_shape
	var offset := ducking_offset if ducked else standing_offset

	body_collider.shape = shape
	body_collider.position = offset

	hurtbox_collider.shape = shape
	hurtbox_collider.position = offset - hurtbox.position


func _check_wall_grab_trigger() -> bool:
	if not has_ability(Ability.PECK_CLIMB):
		return false
	if is_on_floor():
		return false
	if not beak_attack.is_active():
		return false
	if wall_released_this_frame:
		return false
	var hit := probe_wall(facing_dir)
	if hit.is_empty():
		return false
	beak_attack.cancel()
	state_machine.transition_to("wall", {"contact_point": hit["position"]})
	return true


func probe_wall(dir: int) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var beak_offset := get_beak_offset(dir)
	var origin := global_position + Vector2(0.0, beak_offset.y)
	var probe_distance := absf(beak_offset.x) + 2.0
	var target := origin + Vector2(probe_distance * dir, 0.0)

	var query := PhysicsRayQueryParameters2D.create(origin, target)
	# NOTE: Hard-coded because the engine REALLY isn't good at naming collision layers
	query.collision_mask = 1 << 2
	query.exclude = [get_rid()]

	var result := space_state.intersect_ray(query)
	return result



func has_wall_in_front(dir: int) -> bool:
	return not probe_wall(dir).is_empty()


func get_beak_offset(dir: int) -> Vector2:
	var local := beak_anchor - sprite_frame_size / 2.0
	local.x *= -dir
	return animated_sprite_2d.position + local


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
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0:
		facing_dir = 1
		animated_sprite_2d.flip_h = false
		
	#TODO: Hacky, REMOVE 
	cam  = get_viewport().get_camera_2d() as Cam
	$RemoteTransform2D.remote_path = cam.get_path()
	$RemoteTransform2D.position.x = cam.look_ahead_distance * facing_dir


func reset(global_pos: Vector2) -> void:
	global_position = global_pos
	velocity = Vector2.ZERO
	state_machine.transition_to("reset")
	state_machine.transition_to(state_machine.initial_state_name)
	hurtbox.reset()


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


func register_camera(camera:Cam) -> void:
	remote_transform_2d.remote_path = camera.get_path()
	cam = camera
