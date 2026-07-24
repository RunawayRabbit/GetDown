extends CanvasLayer

@export_file("*.json") var dialogue_file_path: String

# Color settings for active vs background character
@export var active_col: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var fade_col: Color = Color(0.4, 0.4, 0.4, 1.0)

@onready var left_dude: TextureRect = $LeftDude
@onready var right_dude: TextureRect = $RightDude
@onready var speaker_name: Label = $Panel/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/DialogueText


## Typing speed in seconds per character. Yea that's inverted from what makes most sense,
## fuck you I'm tired.
@export var text_speed: float = 0.03

var dialogue_data: Array = []
var current_index: int = 0
var tween: Tween
var is_typing: bool = false

signal dialogue_finished

func _ready() -> void:
	hide()

func start_dialogue(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_error("Dialogue file not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		dialogue_data = json.data
		current_index = 0
		
		# Pause the entire game and display UI
		get_tree().paused = true
		show()
		show_line()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		if is_typing:
			if tween and tween.is_running():
				tween.kill()
			dialogue_text.visible_characters = -1
			is_typing = false
		else:
			current_index += 1
			if current_index < dialogue_data.size():
				show_line()
			else:
				finish_dialogue()

func finish_dialogue() -> void:
	hide()
	get_tree().paused = false # Unpause the game!
	dialogue_finished.emit()

func show_line() -> void:
	var line: Dictionary = dialogue_data[current_index]
	speaker_name.text = line.get("name", "")
	dialogue_text.text = line.get("text", "")
	
	dialogue_text.visible_characters = 0
	is_typing = true
	
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	var char_count = dialogue_text.get_total_character_count()
	
	# Tweens also respect process mode!
	tween.tween_property(dialogue_text, "visible_characters", char_count, char_count * text_speed)
	tween.finished.connect(func(): is_typing = false)
	
	# Modulate portraits based on who is speaking
	var speaker: String = line.get("speaker", "left")
	if speaker == "left":
		left_dude.modulate = active_col
		right_dude.modulate = fade_col
	else:
		left_dude.modulate = fade_col
		right_dude.modulate = active_col
