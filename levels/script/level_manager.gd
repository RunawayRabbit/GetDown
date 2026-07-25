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
var _game_manager: GameManager
var _scene_file_path: String = ""

signal escape_timer_started(seconds: float)
signal escape_failed
signal wing_completed


func initialize(game_manager: GameManager, path: String, resume_after_golden: bool = false) -> void:
	_game_manager = game_manager
	_scene_file_path = path

	for door in doors:
		door.initialize(game_manager)

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
	escape_timer_started.emit(escape_time_seconds)


func _on_escape_timer_timeout() -> void:
	escape_failed.emit()
	_game_manager.retry_active_wing(true)


## Called by this level's Door once the player reaches its ReturnZone with
## the golden feather in hand.
func complete() -> void:
	_timer.stop()
	wing_completed.emit()
	_game_manager.mark_wing_complete(wing_id)
