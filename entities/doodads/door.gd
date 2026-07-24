extends Node2D
class_name Door

## The PackedScene this door leads to.
@export_file("*.tscn") var destination: String
## The GameManager in the scene. Please set it and be nice to me.

var game_manager: GameManager

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area_trigger: Area2D = $Area2D

enum State { CLOSED, OPENING, WAITING_FOR_LEVEL, OPEN }
var state := State.CLOSED


func initialize(manager:GameManager) -> void:
	self.game_manager = manager
	
func _ready() -> void:
	game_manager.level_loaded.connect(_on_level_loaded)
	area_trigger.body_entered.connect(player_entered)
	DebugDisplay.watch("DoorState", func(): return state)


func _exit_tree() -> void:
	if game_manager and game_manager.level_loaded.is_connected(_on_level_loaded):
		game_manager.level_loaded.disconnect(_on_level_loaded)


func player_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	
	if state != State.CLOSED:
		return

	state = State.OPENING
	#anim.play("open_to_wait")
	game_manager.load_level(destination, global_position)



func _on_level_loaded(scene_path: String, level: LevelManager) -> void:
	if state != State.WAITING_FOR_LEVEL:
		return

	if scene_path != destination:
		return

	# Position the level however your game needs.
	game_manager.level_container.add_child(level)

	state = State.OPEN

	#anim.play("open_finish")


func player_left() -> void:
	if state == State.OPEN:
		return

	state = State.CLOSED

	#anim.play_backwards("open_to_wait")
