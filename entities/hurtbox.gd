extends Area2D
class_name Hurtbox

## Emitted after taking daamge. source is whatever was passed into
## take_damage() and is probably the thing that you took damage from.
signal damaged(amount: int, source: Node2D)
## Emitted once on death.
signal died
## Emitted on "damaged" or "died". For health bars.
signal health_changed(current: int, max: int)

## Guess.
@export var max_health: int = 3

## Iframes, but in seconds and not frames cuz it's 2026 boyyyyyyyyyeeeeeee
@export var invincibility_time: float = 0.5

var current_health: int
var _invincible_timer: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	monitoring = false
	monitorable = true

func _physics_process(delta: float) -> void:
	if _invincible_timer > 0.0:
		_invincible_timer -= delta

## amount must be positive. source is optional but appreciated.
func take_damage(amount: int, source: Node2D = null) -> void:
	if _is_dead or _invincible_timer > 0.0:
		return

	current_health = maxi(current_health - amount, 0)
	_invincible_timer = invincibility_time

	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_is_dead = true
		died.emit()

func is_invincible() -> bool:
	return _invincible_timer > 0.0

func is_dead() -> bool:
	return _is_dead
