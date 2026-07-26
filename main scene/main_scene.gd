extends Node

@onready var game_manager: GameManager = $GameManager
@onready var ui_shell: UIShell = $UIShell


func _ready() -> void:
	ui_shell.game_started.connect(_on_game_started)
	ui_shell.game_paused.connect(_on_game_paused)
	ui_shell.game_resumed.connect(_on_game_resumed)
	MusicManager.play_music(load("res://Music/Epic Intro Theme.mp3"), false)


func _on_game_started() -> void:
	MusicManager.play_music(load("res://Music/Throne Room Loopable.mp3"), false, true)
	pass


#TODO: These turned out to be redundant. PauseManager ended up being needed..
func _on_game_paused() -> void:
	pass


func _on_game_resumed() -> void:
	pass
