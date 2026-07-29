extends CanvasLayer

@export_file("*.json") var dialogue_file_path: String

# Color settings for active vs background character
@export var active_col: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var fade_col: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var pitch_min: float = 0.9
@export var pitch_max: float = 1.1

@export_category("Left Dude")
@onready var left_dude: TextureRect = $LeftDude
@export var left_dude_clips: Array[AudioStream] = []
@export var left_dude_shout: AudioStream
@export var left_dude_sigh: AudioStream

@export_category("Right Dude")
@onready var right_dude: TextureRect = $RightDude
@export var right_dude_clips: Array[AudioStream] = []
@export var right_dude_shout: AudioStream
@export var right_dude_sigh: AudioStream


@onready var speaker_name: Label = $Panel/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/DialogueText
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

const PAUSE_REASON: StringName = &"dialogue"

## Typing speed in seconds per character. Yea that's inverted from what makes most sense,
## fuck you I'm tired.
@export var text_speed: float = 0.03

var _dialogue_data: Array = []
var _current_index: int = 0
var _tween: Tween
var _is_typing: bool = false
var _is_left_dude_speaking = true

#Getting out of hand. Refactor.
var _is_shouting = false
var _is_silent = false
var _is_sigh = false

var current_dialogue_path: String = ""

var game_manager:GameManager

var dialogue_cooldown: Timer = Timer.new()

signal dialogue_finished


# This is what we call a Stringly Typed system.
# I won't tell anyone if you don't.
class DialogueGroup:
	func _init(wing_:String, files_: Array[String]):
		wing = wing_
		files = files_
	var wing: String
	var files: Array[String]

# wing names are the level we are *going to*. Names must match GameManager's version because OOF
# I am not programming well today.
var DIALOGUE_LISTS: Array[DialogueGroup] = [
	DialogueGroup.new("tutorial", ["res://dialogue/beginning.json"]),
	DialogueGroup.new("duck", ["res://dialogue/chargejump.json"]),
	DialogueGroup.new("yoshi", ["res://dialogue/hover.json"]),
	DialogueGroup.new("peck", ["res://dialogue/wallpeck.json"]),
	DialogueGroup.new("end", ["res://dialogue/ending.json"]),
]

var _seen_dialogues: Dictionary[String, bool] = {}

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	dialogue_cooldown.one_shot = true
	add_child(dialogue_cooldown)
	
	# Configure audio player
	audio_stream_player.finished.connect(_on_audio_finished)


func _play_voice_clip() -> void:
	var clip = _pick_clip()
	if not _is_typing or not clip:
		return
	
	audio_stream_player.stream = clip
	audio_stream_player.pitch_scale = randf_range(pitch_min, pitch_max)
	audio_stream_player.play()


func _pick_clip() -> AudioStream:
	if _is_silent == true: return null
	if _is_shouting == true: return left_dude_shout if _is_left_dude_speaking else right_dude_shout
	if _is_sigh == true: return left_dude_sigh if _is_left_dude_speaking else right_dude_sigh
	
	var voice_clips = left_dude_clips if _is_left_dude_speaking else right_dude_clips
	if voice_clips.is_empty(): return null
	
	return voice_clips.pick_random()
	

func _on_audio_finished() -> void:
	_play_voice_clip()

func start_next_dialogue() -> void:
	for stage in DIALOGUE_LISTS:
		game_manager._player.add_ability(stage.wing)
		if game_manager.is_wing_complete(stage.wing):
			continue

		for file in stage.files:
			if !has_seen_dialogue(file):
				start_dialogue(file)
				return

		# Repeat the final one.
		start_dialogue(stage.files[-1])
		return
	
	assert(false) # unreachable

func has_seen_dialogue(dialogue: String) -> bool:
	return _seen_dialogues.has(dialogue)

func mark_dialogue_seen(dialogue: String) -> void:
	_seen_dialogues[dialogue] = true

func start_dialogue(file_path: String) -> void:
	if !dialogue_cooldown.is_stopped(): return
	
	if not FileAccess.file_exists(file_path):
		push_error("Dialogue file not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		current_dialogue_path = file_path
		_dialogue_data = json.data
		_current_index = 0
		
		# Pause the entire game and display UI
		Pause.request_pause(PAUSE_REASON)
		show()
		show_line()

func _unhandled_input(event: InputEvent) -> void:
	if not Pause.is_topmost(PAUSE_REASON):
		return

	if event.is_action_pressed("ui_accept") or \
	   event.is_action_pressed("honk") or \
	   (event is InputEventMouseButton and \
		event.is_pressed() and \
		event.button_index == MOUSE_BUTTON_LEFT):
		if _is_typing:
			if _tween and _tween.is_running():
				_tween.kill()
			dialogue_text.visible_characters = -1
			_is_typing = false
		else:
			_current_index += 1
			if _current_index < _dialogue_data.size():
				show_line()
			else:
				finish_dialogue()

func finish_dialogue() -> void:
	audio_stream_player.stop()
	_is_typing = false
	hide()
	Pause.release_pause(PAUSE_REASON)
	mark_dialogue_seen(current_dialogue_path)
	current_dialogue_path = ""
	dialogue_cooldown.start(1.0)
	dialogue_finished.emit()

func show_line() -> void:
	var line: Dictionary = _dialogue_data[_current_index]
	speaker_name.text = line.get("name", "")
	dialogue_text.text = line.get("text", "")
	
	dialogue_text.visible_characters = 0
	_is_typing = true
	
	if _tween and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	var char_count = dialogue_text.get_total_character_count()
	
	# Tweens also respect process mode!
	_tween.tween_property(dialogue_text, "visible_characters", char_count, char_count * text_speed)
	_tween.finished.connect(func(): _is_typing = false)
	
	# Modulate portraits based on who is speaking
	var speaker: String = line.get("speaker", "left")
	if speaker == "left":
		_is_left_dude_speaking = true
		left_dude.modulate = active_col
		right_dude.modulate = fade_col
	else:
		_is_left_dude_speaking = false
		left_dude.modulate = fade_col
		right_dude.modulate = active_col
	
	_is_shouting = line.get("shouting", false)
	_is_silent = line.get("silent", false)
	_is_sigh = line.get("sigh", false)
	prints("shout", _is_shouting, "silent", _is_silent, "sigh", _is_sigh)
	_play_voice_clip()
	
