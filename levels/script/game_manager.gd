extends Node
class_name GameManager

@onready var level_container: Node = $LevelContainer
@onready var fadeout: ColorRect = $UI/Fadeout

# Hard-coded as FUCK! It works though. Putting my game jam hat on.
var completed_wings: Dictionary = {
	"wing_north": false,	
	"wing_south": false,
	"wing_east": false,
	"wing_west": false
}


var _active_level: LevelManager = null
var _loading_level: String = ""
var _staged_level: String = ""
var _is_loading: bool = false
var _loading_position: Vector2 = Vector2.ZERO

const throne_room_scene = preload("res://levels/sandbox.tscn")
const player_scene = preload("res://entities/character/character.tscn")
const camera_scene = preload("res://camera/camera.tscn")



signal wing_completed(wing_id: String)
signal level_loaded(scene_path: String, level: LevelManager)

func _ready() -> void:
	fadeout.modulate.a = 1.0
	_fade(0.0, 2.0)
		
	var throne_room = throne_room_scene.instantiate() as LevelManager
	
	var camera = camera_scene.instantiate() as Cam
	add_child(camera)
	
	# TODO: Remember to change this to the correct scene when throne room is in..
	throne_room.initialize(self, "res://levels/sandbox.tscn")
	level_container.add_child(throne_room)

	
	var player = spawn_player(Vector2.ZERO)
	player.register_camera(camera)
	

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


func spawn_player(position:Vector2) -> CharacterController:
	var player = player_scene.instantiate() as CharacterController
	player.game_manager = self
	player.global_position = position
	add_child(player)
	return player


func load_level(scene_path: String, global_position:Vector2) -> void:
	if _active_level and scene_path == _active_level.scene_file_path:
		return

	_staged_level = scene_path
	_loading_position = global_position

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
	level.initialize(self, finished_path)
	level.global_position = _loading_position
	level_container.add_child(level)
	_active_level = level
	level_loaded.emit(finished_path, level)
	
	_loading_position = Vector2.ZERO


## Call this when a wing's escape sequence is successfully finished
func mark_wing_complete(wing_id: String) -> void:
	if completed_wings.has(wing_id):
		completed_wings[wing_id] = true
		wing_completed.emit(wing_id)


## Call this if the player dies or the escape timer expires
func player_died(current_wing: String) -> void:
	#TODO: Placeholder
	pass


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
