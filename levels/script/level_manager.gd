extends Node
class_name LevelManager

## Set up the doors. Sorry in advance.
@export var doors: Array[Door]
## Regular feathers go here.
@export var collectables: Array[Collectable]
## Our ONE AND ONLY golden feather.
@export var golden_feather: GoldenFeather
## Spawnpoint for heading back.
@export var golden_feather_spawn: Marker2D
## Matches a key in GameManager.completed_wings. Janky but it will work.
@export var wing_id: String = ""

# How long you have to get out of the level after picking up the golden feather.
@export var escape_time_seconds: float = 20.0

var has_golden_feather: bool = false
var collected_count: int = 0
var total_collectables: int = 0

var _timer: Timer

## Emitted whenever this level decides a reset is needed - the escape timer
## expiring, or the player dying. Game Manager listens for this.
signal reset_requested(resume_after_golden: bool)
signal escape_timer_started(timer: Timer)
signal escape_failed
signal wing_completed


## The only thing a level needs to know about the outside world at start:
## whether it's beginning fresh, or resuming with the golden feather already
## collected.
func initialize(resume_after_golden: bool = false) -> void:
	total_collectables = collectables.size()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_escape_timer_timeout)
	add_child(_timer)

	for c in collectables:
		c.picked_up.connect(_on_collectable_collected)
	
	if golden_feather:
		golden_feather.picked_up.connect(_on_golden_feather_collected)

		if resume_after_golden:
			_resume_with_golden_feather()
		else:
			golden_feather.set_locked(true)
			_update_golden_feather_lock() # covers the zero-collectables edgecase


func _resume_with_golden_feather() -> void:
	has_golden_feather = true
	collected_count = total_collectables

	for c in collectables:
		if is_instance_valid(c):
			c.queue_free()
	if is_instance_valid(golden_feather):
		golden_feather.queue_free()

	_start_escape_timer()


func _on_collectable_collected(_collectable: Collectable) -> void:
	collected_count += 1
	_update_golden_feather_lock()


func _update_golden_feather_lock() -> void:
	if collected_count >= total_collectables:
		golden_feather.set_locked(false)


func _on_golden_feather_collected(_feather: Collectable) -> void:
	has_golden_feather = true
	_start_escape_timer()


func _start_escape_timer() -> void:
	_timer.start(escape_time_seconds)
	escape_timer_started.emit(_timer)


func _on_escape_timer_timeout() -> void:
	escape_failed.emit()
	reset_requested.emit(true)


## Call this when the player dies. CharacterController will do the reset.
func on_player_died() -> void:
	reset_requested.emit(has_golden_feather)


## Called by this level's Door once the player reaches its ReturnZone with
## the golden feather in hand.
func complete() -> void:
	if _timer.is_stopped(): return
	DebugDisplay.remove_watch("Timer")

	_timer.stop()
	wing_completed.emit()
