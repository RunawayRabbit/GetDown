extends Node2D
class_name Door

## The PackedScene this door leads to.
@export_file("*.tscn") var destination: String


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var open_zone: Area2D = $OpenZone

# Cool pattern for defaults. Variants are risky AF but kinda nice if they can be trusted to just work.
@onready var level_anchor: Marker2D = $LevelAnchor if has_node("LevelAnchor") else null
@onready var return_zone: Area2D = $ReturnZone if has_node("ReturnZone") else null

var _game_manager: GameManager
var _level: LevelManager = null

var _is_open: bool = false
var _needs_fresh_load: bool = true

# Called by GameManager before _ready().
func initialize(manager: GameManager) -> void:
	self._game_manager = manager


func _ready() -> void:
	if _game_manager: _game_manager.level_loaded.connect(_on_level_loaded)
	open_zone.body_entered.connect(_on_body_entered)

	if return_zone:
		return_zone.body_entered.connect(_on_return_zone_entered)


	if not level_anchor:
		push_warning("%s has no LevelAnchor Marker2D — falling back to door position." % name)
	if not return_zone:
		push_warning("%s has no ReturnZone Area2D — wing completion can't be detected." % name)

	anim.play("RESET")

func _exit_tree() -> void:
	if _game_manager and _game_manager.level_loaded.is_connected(_on_level_loaded):
		_game_manager.level_loaded.disconnect(_on_level_loaded)


func _on_level_loaded(scene_path: String, level: LevelManager) -> void:
	if scene_path != destination:
		_close()
		return

	_level = level
	_needs_fresh_load = false

	_open()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return

	if _is_open:
		return

	var currently_active := _game_manager.get_loaded_wing(destination)

	if currently_active and not _needs_fresh_load:
		_level = currently_active
		_open()
		return

	var anchor := level_anchor.global_position if level_anchor else global_position

	anim.play("waiting")
	# enter_wing (not load_level) - it's the one entry point that knows
	# whether this is a brand new wing or a retry of the one already active.
	_game_manager.enter_wing(destination, anchor)



func _open() -> void:
	if _is_open:
		return

	_is_open = true
	anim.play("opening")


func _on_return_zone_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if not _is_open: return
	if not is_instance_valid(_level) or not _level.has_golden_feather: return

	_level.complete()
	_close()


func _close() -> void:
	_is_open = false
	_needs_fresh_load = true # This instance is spent - next approach needs a reload.

	anim.play("closing")
