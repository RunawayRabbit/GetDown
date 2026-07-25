extends CanvasLayer
class_name UIShell

# Expected node structure (build this in the editor, it's just a couple of
# Controls and buttons — not worth hand-authoring a .tscn for):
#
# UIShell (CanvasLayer)  <- this script
# ├── TitleScreen (Control, full rect)
# │   └── StartButton (Button)
# └── PauseMenu (Control, full rect, Visible = off)
#     ├── ResumeButton (Button)
#     └── QuitButton (Button)
#
# Set this node's Process Mode to "Always" in the editor (or leave it to
# _ready() below) so it keeps responding while the tree is paused — that's
# the whole trick. GameManager and everything under it default to
# "Inherit"/"Pausable", so pausing the tree freezes gameplay with zero extra
# code on GameManager's side.

signal game_started
signal game_resumed
signal game_paused

@onready var title_screen: Control = $TitleScreen
@onready var pause_menu: Control = $PauseMenu
@onready var start_button: Button = $TitleScreen/StartButton
@onready var resume_button: Button = $PauseMenu/VBoxContainer/ResumeButton
@onready var quit_button: Button = $PauseMenu/VBoxContainer/QuitButton

@onready var fadeout: ColorRect = $Fadeout
var active_fade_tween: Tween

## How opaque the fadeout element should be while paused.
@export var fade_alpha: float = 0.6
## How long it should take to tween towards the fade timer.
@export var fade_time: float = 0.4

var _game_started: bool = false

func fade_to(target_alpha: float, duration_seconds: float) -> void:
	# Kill any existing fade in progress so they don't fight
	if active_fade_tween and active_fade_tween.is_running():
		active_fade_tween.kill()
		
	active_fade_tween = create_tween()
	active_fade_tween.tween_property(fadeout, "modulate:a", target_alpha, duration_seconds)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Boot straight into the title screen with the world frozen behind it.
	get_tree().paused = true
	title_screen.show()
	pause_menu.hide()

	start_button.pressed.connect(_on_start_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	# Don't let ui_cancel open the pause menu before the game has even started.
	if not _game_started:
		return

	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _on_start_pressed() -> void:
	_game_started = true
	title_screen.hide()
	get_tree().paused = false
	game_started.emit()


func _toggle_pause() -> void:
	if pause_menu.visible:
		_on_resume_pressed()
	else:
		fade_to(fade_alpha, fade_time)
		pause_menu.show()
		get_tree().paused = true
		game_paused.emit()


func _on_resume_pressed() -> void:
	fade_to(0.0, 0.1)
	pause_menu.hide()
	get_tree().paused = false
	game_resumed.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()
