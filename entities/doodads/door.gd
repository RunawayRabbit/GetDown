extends Node2D
class_name Door

## The PackedScene this door leads to.
@export_file("*.tscn") var destination: String


@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var open_zone: Area2D = $OpenZone

# Cool pattern for defaults. Variants are risky AF but kinda nice if they can be trusted to just work.
@onready var level_anchor: Marker2D = $LevelAnchor if has_node("LevelAnchor") else null
@onready var return_zone: Area2D = $ReturnZone if has_node("ReturnZone") else null

enum State { CLOSED, OPENING, WAITING_FOR_LEVEL, OPEN, CLOSING }
var state := State.CLOSED

var _game_manager: GameManager
var _level: LevelManager = null

# Called by GameManager before _ready().
func initialize(manager: GameManager) -> void:
	self._game_manager = manager


func _ready() -> void:
	if _game_manager: _game_manager.level_loaded.connect(_on_level_loaded)
	open_zone.body_entered.connect(_on_body_entered)

	if return_zone:
		return_zone.body_entered.connect(_on_return_zone_entered)

	DebugDisplay.watch("DoorState", func(): return state)

	if not level_anchor:
		push_warning("%s has no LevelAnchor Marker2D — falling back to door position." % name)
	if not return_zone:
		push_warning("%s has no ReturnZone Area2D — wing completion can't be detected." % name)

	anim.play("RESET")

func _exit_tree() -> void:
	if _game_manager and _game_manager.level_loaded.is_connected(_on_level_loaded):
		_game_manager.level_loaded.disconnect(_on_level_loaded)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return

	if state != State.CLOSED:
		return

	state = State.WAITING_FOR_LEVEL
	var anchor := level_anchor.global_position if level_anchor else global_position

	# enter_wing (not load_level) - it's the one entry point that knows
	# whether this is a brand new wing or a retry of the one already active.
	_game_manager.enter_wing(destination, anchor)

	anim.play("waiting")


func _on_level_loaded(scene_path: String, level: LevelManager) -> void:
	if scene_path != destination:
		return

	_level = level

	if state != State.WAITING_FOR_LEVEL:
		return

	# GameManager already parents the level under level_container by this
	# point — this handler is purely a reaction to it being ready.
	state = State.OPENING
	anim.play("opening")
	await anim.animation_finished

	state = State.OPEN


func _on_return_zone_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if state != State.OPEN: return
	if not _level or not _level.has_golden_feather: return

	_level.complete()

	state = State.CLOSING
	anim.play("closing")
	await anim.animation_finished

	state = State.CLOSED
	_level = null
