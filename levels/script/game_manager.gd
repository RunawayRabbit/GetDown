extends Node
class_name GameManager

@onready var level_container: Node = $LevelContainer
@onready var fadeout: ColorRect = $"../UIShell/Fadeout"

# Hard-coded as FUCK! It works though. Putting my game jam hat on.
var completed_wings: Dictionary = {
	"yoshi": false,
	"climb": false,
	"tutorial": false,
	"duck": false
}

var _active_wing: LevelManager = null
var _active_wing_anchor: Vector2 = Vector2.ZERO
var _hub: LevelManager = null
var _throne_room_path: String = ""
var _player: CharacterController = null

var _loading_level: String = ""
var _staged_level: String = ""
var _is_loading: bool = false
var _loading_position: Vector2 = Vector2.ZERO

const throne_room_scene = preload("res://levels/throne_room.tscn")
const player_scene = preload("res://entities/character/character.tscn")
const camera_scene = preload("res://camera/camera.tscn")


signal wing_completed(wing_id: String)
signal level_loaded(scene_path: String, level: LevelManager)


func _ready() -> void:
	fadeout.modulate.a = 1.0
	_fade(0.0, 2.0)
	DebugDisplay.watch("Wings Cleared", func(): return  completed_wings)

	_throne_room_path = throne_room_scene.resource_path
	var throne_room = throne_room_scene.instantiate() as LevelManager

	var camera = camera_scene.instantiate() as Cam
	add_child(camera)

	# TODO: Remember to change this to the correct scene when throne room is in..
	throne_room.initialize(self, _throne_room_path)
	level_container.add_child(throne_room)
	_hub = throne_room

	_player = spawn_player(Vector2.ZERO)
	_player.register_camera(camera)


func _process(_delta: float) -> void:
	if not _is_loading:
		return

	match ResourceLoader.load_threaded_get_status(_loading_level):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return

		ResourceLoader.THREAD_LOAD_LOADED:
			_finish_load()

		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load %s" % _loading_level)

			_is_loading = false
			_loading_level = ""

			if _staged_level != "":
				_begin_load(_staged_level)


func spawn_player(position: Vector2) -> CharacterController:
	var player = player_scene.instantiate() as CharacterController
	player.game_manager = self
	player.global_position = position
	add_child(player)
	return player



func enter_wing(scene_path: String, anchor_position: Vector2) -> void:
	if _active_wing and scene_path == _active_wing.scene_file_path:
		_active_wing_anchor = anchor_position
		retry_active_wing(false)
		return

	load_level(scene_path, anchor_position)


func load_level(scene_path: String, anchor_position: Vector2) -> void:
	# Throne Room is never unloaded, so returning to it skips the loader.
	if scene_path == _throne_room_path:
		_return_to_hub()
		return

	_staged_level = scene_path
	_loading_position = anchor_position

	# Something is already loading.
	if _is_loading:
		return

	_begin_load(scene_path)


func _begin_load(scene_path: String) -> void:
	_loading_level = scene_path
	_is_loading = true

	ResourceLoader.load_threaded_request(scene_path)


func _finish_load() -> void:
	var finished_path := _loading_level

	var packed: PackedScene = ResourceLoader.load_threaded_get(finished_path)

	_is_loading = false
	_loading_level = ""

	if finished_path != _staged_level:
		_begin_load(_staged_level)
		return

	var level: LevelManager = packed.instantiate()
	level.global_position = _loading_position
	level_container.add_child(level)
	level.initialize(self, finished_path)

	# Why maintain a dirty list and do *actual programming* when you can just
	# TURN IT OFF AND ON AGAIN?!?!?!?!
	if _active_wing and is_instance_valid(_active_wing):
		_active_wing.queue_free()

	_active_wing = level
	_active_wing_anchor = _loading_position
	level_loaded.emit(finished_path, level)

	_loading_position = Vector2.ZERO


func _return_to_hub() -> void:
	if _active_wing and is_instance_valid(_active_wing):
		_active_wing.queue_free()
		_active_wing = null

	level_loaded.emit(_throne_room_path, _hub)


func retry_active_wing(resume_after_golden: bool) -> void:
	if not _active_wing:
		return

	var scene_path := _active_wing.scene_file_path
	var anchor := _active_wing_anchor

	await _fade(1.0, 0.4)

	_active_wing.queue_free()

	var level: LevelManager = load(scene_path).instantiate()
	level.global_position = anchor
	level_container.add_child(level)
	level.initialize(self, scene_path, resume_after_golden)

	_active_wing = level

	_player.global_position = level.golden_feather_spawn.global_position if resume_after_golden else anchor
	_player.reset()
	
	level_loaded.emit(scene_path, level)

	await _fade(0.0, 0.4)


## Call this when the player dies. Decides hard vs. soft restart based on
## whether the currently active wing's golden feather has been collected.
func player_died() -> void:
	if not _active_wing:
		return # Dying in the hub isn't handled yet - no hazards live there currently.

	retry_active_wing(_active_wing.has_golden_feather)


## Call this when a wing's escape sequence is successfully finished
func mark_wing_complete(wing_id: String) -> void:
	if completed_wings.has(wing_id):
		completed_wings[wing_id] = true
		wing_completed.emit(wing_id)



func are_all_wings_complete() -> bool:
	for wing in completed_wings:
		if not completed_wings[wing]:
			return false
	return true


### Smooth screen fade helper
func _fade(target_alpha: float, duration: float) -> void:
	if not fadeout:
		return

	fadeout.mouse_filter = Control.MOUSE_FILTER_STOP if target_alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(fadeout, "modulate:a", target_alpha, duration)
	await tween.finished
