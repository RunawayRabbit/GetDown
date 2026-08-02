extends Node
class_name GameManager

@onready var level_container: Node = $LevelContainer
@onready var fadeout: ColorRect = %Fadeout
@onready var timer_display: TimerDisplay = %TimerDisplay

# Hard-coded as FUCK! It works though. Putting my game jam hat on.
var completed_wings: Dictionary = {
	"tutorial": false,
	"duck": false,
	"yoshi": false,
	"peck": false
}

var _active_wing: LevelManager = null
var _active_wing_anchor: Vector2 = Vector2.ZERO
var _active_wing_scene_path: String = ""
var _hub: LevelManager = null
var _throne_room_uid: String = ""
var _player: CharacterController = null

var _loading_level: String = ""
var _staged_level: String = ""
var _is_loading: bool = false
var _loading_position: Vector2 = Vector2.ZERO

var _escape_timer: Timer = null

const throne_room_scene = preload("res://levels/throne_room.tscn")
const player_scene = preload("res://entities/character/character.tscn")
const camera_scene = preload("res://camera/camera.tscn")


signal wing_completed(wing_id: String)
signal level_loaded(scene_path: String, level: LevelManager)


func _ready() -> void:
	fadeout.modulate.a = 1.0
	fadeout.fade(0.0, 2.0)

	_escape_timer = Timer.new()
	_escape_timer.one_shot = true
	_escape_timer.timeout.connect(_on_escape_timer_timeout)
	add_child(_escape_timer)

	_throne_room_uid = throne_room_scene.resource_path
	var throne_room = throne_room_scene.instantiate() as LevelManager

	var camera = camera_scene.instantiate() as Cam
	add_child(camera)

	_wire_doors(throne_room)
	level_container.add_child(throne_room)
	throne_room.initialize()
	_wire_level(throne_room)
	_hub = throne_room

	_player = spawn_player(Vector2.ZERO)
	_player.register_camera(camera)
	_player.hurtbox.died.connect(_on_player_died)

	DialogueManager.game_manager = self
	Pause.player = _player


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


func grant_ability(ability: String) -> void:
	if _player:
		_player.add_ability(ability)


func spawn_player(position: Vector2) -> CharacterController:
	var player = player_scene.instantiate() as CharacterController
	player.global_position = position
	add_child(player)
	return player


## Returns the currently active wing if it matches scene_path, else null.
func get_loaded_wing(scene_path: String) -> LevelManager:
	if _active_wing and scene_path == _active_wing_scene_path:
		return _active_wing
	return null


func enter_wing(scene_path: String, anchor_position: Vector2) -> void:
	if _active_wing and scene_path == _active_wing_scene_path:
		_active_wing_anchor = anchor_position
		_reload_active_wing(false, false)
		return

	load_level(scene_path, anchor_position)



func load_level(scene_path: String, anchor_position: Vector2) -> void:
	# Throne Room is never unloaded, so returning to it skips the loader.
	if scene_path == _throne_room_uid:
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
	_wire_doors(level)
	level_container.add_child(level)

	# Why maintain a dirty list and do *actual programming* when you can just
	# TURN IT OFF AND ON AGAIN?!?!?!?!
	if _active_wing and is_instance_valid(_active_wing):
		_active_wing.queue_free()

	_active_wing = level
	_active_wing_anchor = _loading_position
	_active_wing_scene_path = finished_path

	# Emit before initialize()
	level_loaded.emit(finished_path, level)
	_wire_level(level)
	level.initialize() # Fresh start - no golden feather to resume from.

	_loading_position = Vector2.ZERO


func _wire_doors(level: LevelManager) -> void:
	for door in level.doors:
		door.initialize(self)


func _wire_level(level: LevelManager) -> void:
	level.escape_timer_start_requested.connect(_on_escape_timer_start_requested)
	level.wing_completed.connect(func(): _on_wing_completed(level))
	level.reset_requested.connect(_on_reset_requested)


func _on_escape_timer_start_requested(duration: float) -> void:
	_escape_timer.start(duration)
	timer_display.start_timer(_escape_timer)


func _on_escape_timer_timeout() -> void:
	timer_display.end_timer()

	if _active_wing:
		_active_wing.on_escape_timeout()


func _on_wing_completed(level: LevelManager) -> void:
	_escape_timer.stop() # Stop the actual countdown, not just the UI - otherwise a near-simultaneous timeout could still fire and trigger a bogus reset after a successful finish.
	timer_display.freeze_timer()
	mark_wing_complete(level.wing_id)


func _return_to_hub() -> void:
	if _active_wing and is_instance_valid(_active_wing):
		_active_wing.queue_free()
		_active_wing = null

	level_loaded.emit(_throne_room_uid, _hub)


## Requests come from LevelManager, we just do what it asks for.
func _on_reset_requested(resume_after_golden: bool) -> void:
	_reload_active_wing(resume_after_golden, true)


func _reload_active_wing(resume_after_golden: bool, is_forced_respawn: bool) -> void:
	if not _active_wing:
		return

	var scene_path := _active_wing_scene_path
	var anchor := _active_wing_anchor

	if is_forced_respawn:
		await fadeout.fade(1.0, 0.4)

	_active_wing.queue_free()

	var level: LevelManager = load(scene_path).instantiate()
	level.global_position = anchor
	_wire_doors(level)
	level_container.call_deferred("add_child", level)

	_active_wing = level

	level_loaded.emit(scene_path, level)
	_wire_level(level)
	level.initialize(resume_after_golden)

	var target_position := _player.global_position
	if is_forced_respawn:
		target_position = anchor
	if resume_after_golden:
		if level.golden_feather_spawn:
			target_position = level.golden_feather_spawn.global_position
		else:
			push_warning("%s has no golden_feather_spawn Marker2D set - falling back to the entrance anchor." % level.name)

	_player.reset(target_position)

	if is_forced_respawn:
		await fadeout.fade(0.0, 0.4)


## Call this when the player dies.
func _on_player_died() -> void:
	if not _active_wing:
		push_error("How the fuck did you die in the throne room? Seriously, tell me.")
		return

	_active_wing.on_player_died()


## Call this when a wing's escape sequence is successfully finished
func mark_wing_complete(wing_id: String) -> void:
	if completed_wings.has(wing_id):
		completed_wings[wing_id] = true
		wing_completed.emit(wing_id)


func is_wing_complete(wing_id: String) -> bool:
	return completed_wings.get(wing_id, false)


func are_all_wings_complete() -> bool:
	for wing in completed_wings:
		if not completed_wings[wing]:
			return false
	return true
