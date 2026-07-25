extends CanvasLayer
class_name UIShell


signal game_started
signal game_resumed
signal game_paused


@onready var title_screen: Control = $TitleScreen
@onready var pause_menu: Control = $PauseMenu
@onready var options_menu: OptionsMenu = $OptionsMenu


@onready var start_button: Button = $TitleScreen/StartButton
@onready var title_options_button: Button = $TitleScreen/OptionsButton


@onready var resume_button: Button = $PauseMenu/VBoxContainer/ResumeButton
@onready var pause_options_button: Button = $PauseMenu/VBoxContainer/OptionsButton
@onready var quit_button: Button = $PauseMenu/VBoxContainer/QuitButton


@onready var fadeout: ColorRect = $Fadeout
var active_fade_tween: Tween


## How opaque the fadeout element should be while paused.
@export var fade_alpha: float = 0.6
## How long it should take to tween towards the fade timer.
@export var fade_time: float = 0.4


var _game_started: bool = false
var _options_return_panel: Control = null


const PAUSE_REASON: StringName = "menu"


func fade_to(target_alpha: float, duration_seconds: float) -> void:
	# Kill any existing fade in progress so they don't fight
	if active_fade_tween and active_fade_tween.is_running():
		active_fade_tween.kill()
		
	active_fade_tween = create_tween()
	active_fade_tween.tween_property(fadeout, "modulate:a", target_alpha, duration_seconds)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Boot straight into the title screen with the world frozen behind it.
	Pause.request_pause("title")
	title_screen.show()
	pause_menu.hide()
	options_menu.hide()

	start_button.pressed.connect(_on_start_pressed)
	title_options_button.pressed.connect(func(): _open_options(title_screen))

	resume_button.pressed.connect(_on_resume_pressed)
	pause_options_button.pressed.connect(func(): _open_options(pause_menu))
	quit_button.pressed.connect(_on_quit_pressed)

	options_menu.closed.connect(_on_options_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not _game_started:
		return

	if event.is_action_pressed("ui_cancel") and not options_menu.visible:
		_toggle_pause()


func _on_start_pressed() -> void:
	_game_started = true
	title_screen.hide()
	Pause.release_pause("title")
	game_started.emit()


func _toggle_pause() -> void:
	if pause_menu.visible:
		_on_resume_pressed()
	else:
		fade_to(fade_alpha, fade_time)
		pause_menu.show()
		Pause.request_pause(PAUSE_REASON)
		game_paused.emit()


func _on_resume_pressed() -> void:
	fade_to(0.0, 0.1)
	pause_menu.hide()
	Pause.release_pause(PAUSE_REASON)
	game_resumed.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_options(return_panel: Control) -> void:
	_options_return_panel = return_panel
	return_panel.hide()
	options_menu.show()


func _on_options_closed() -> void:
	options_menu.hide()
	if _options_return_panel:
		_options_return_panel.show()
