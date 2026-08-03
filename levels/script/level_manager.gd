extends Node
class_name LevelManager

## Set up the doors for the Throne Room.
@export var doors: Array[Door]
## Every switch-door.
@export var switch_doors: Array[SwitchDoor]
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

var _completed: bool = false

signal escape_timer_start_requested(duration: float)

## Emitted whenever this level decides a reset is needed - the escape timer
## expiring, or the player dying. Game Manager listens for this.
signal reset_requested(resume_after_golden: bool)
signal wing_completed


## The only thing a level needs to know about the outside world at start:
## whether it's beginning fresh, or resuming with the golden feather already
## collected.
func initialize(resume_after_golden: bool = false) -> void:
	_auto_discover_collectables()
	total_collectables = collectables.size()

	for c in collectables:
		c.picked_up.connect(_on_collectable_collected)
	
	if golden_feather:
		golden_feather.picked_up.connect(_on_golden_feather_collected)

		if resume_after_golden:
			_resume_with_golden_feather()
		else:
			golden_feather.set_locked(true)
			_update_golden_feather_lock() # covers the zero-collectables edgecase

	for door in switch_doors:
		door.initialize(resume_after_golden)


func _auto_discover_collectables() -> void:
	collectables.clear()
	golden_feather = null

	for node in find_children("*", "Collectable", true, false):
		if node is GoldenFeather:
			if golden_feather:
				push_warning("%s: multiple GoldenFeather nodes found - only one is supported per level." % name)
			golden_feather = node
		else:
			collectables.append(node)


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
	escape_timer_start_requested.emit(escape_time_seconds * Settings.get_timer_scale())


## Called by GameManager
func on_escape_timeout() -> void:
	reset_requested.emit(true)


## Call this when the player dies. CharacterController will do the reset.
func on_player_died() -> void:
	reset_requested.emit(has_golden_feather)


## Called by this level's Door once the player reaches its ReturnZone with
## the golden feather in hand.
func complete() -> void:
	if _completed: return
	_completed = true

	wing_completed.emit()
