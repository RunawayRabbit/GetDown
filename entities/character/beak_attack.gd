extends Node
class_name BeakAttack

@export var attack_duration:float = 0.7
@export var attack_cooldown:float = 1.0

@onready var controller: CharacterController = get_parent()
@onready var hitbox: Area2D = $"../Hitbox"

var _cooldown_timer: float = 0.0
var _active_timer: float = 0.0
var _is_active: bool = false
var _attack_hitbox_offset: float = 0.0
var _is_attack_queued: bool = false


func _ready() -> void:
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	_attack_hitbox_offset = -hitbox.position.x

func get_hitbox_offset() -> float:
	return _attack_hitbox_offset
	
	
func get_shape() -> Shape2D:
	return (hitbox.get_child(0) as CollisionShape2D).shape


func physics_update(delta: float, attack_pressed: bool) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0 and _is_attack_queued:
			_start_attack()
			return

	if _is_active:
		_active_timer -= delta
		if _active_timer <= 0.0:
			_end_attack()
		return

	if attack_pressed:
		if _cooldown_timer <= 0.0:
			_start_attack()
		elif _cooldown_timer <= controller.attack_buffer_time:
			_is_attack_queued = true


func _start_attack() -> void:
	_is_attack_queued = false
	_is_active = true
	_active_timer = attack_duration
	_cooldown_timer = attack_cooldown

	controller.begin_attack_lock(attack_duration)
	controller.force_play_animation("attack")

	hitbox.position.x = _attack_hitbox_offset * controller.facing_dir
	hitbox.set_deferred("monitoring", true)


func _end_attack() -> void:
	_is_active = false
	hitbox.set_deferred("monitoring", false)


func _on_hitbox_area_entered(area: Area2D) -> void:
	_deal_damage(area)


func _on_hitbox_body_entered(body: Node) -> void:
	_deal_damage(body)


## Placeholder damage interface
func _deal_damage(target: Node) -> void:
	if target.has_method("take_damage"):
		target.take_damage(1, controller)
