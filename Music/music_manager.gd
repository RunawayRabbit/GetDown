extends Node

@export var fade_duration: float = 1.0

@onready var track_a: AudioStreamPlayer = $"Track A"
@onready var track_b: AudioStreamPlayer = $"Track B"

# Double Buffer. How else would you do it?
var front_track: AudioStreamPlayer
var back_track: AudioStreamPlayer
var fade_tween: Tween

func _ready() -> void:
	front_track = track_a
	back_track = track_b

func play_music(new_stream: AudioStream, fade_in_new:bool = true, fade_out_old:bool = true) -> void:
	if front_track.stream == new_stream and front_track.playing:
		return

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	var temp = front_track
	front_track = back_track
	back_track = temp

	front_track.stream = new_stream
	front_track.volume_db = -80.0
	front_track.play()


	fade_tween = create_tween().set_parallel(true)

	if back_track.playing:
		if fade_out_old:
			fade_tween.tween_property(back_track, "volume_linear", 0.0, fade_duration)\
				.set_ease(Tween.EASE_OUT)
		else:
			back_track.stop()

	if fade_in_new:
		fade_tween.tween_property(front_track, "volume_linear", 1.0, fade_duration)\
				.set_ease(Tween.EASE_OUT)
	else:
		front_track.volume_linear = 1.0

	fade_tween.chain().tween_callback(func():
		back_track.stop()
		back_track.stream = null
	)

func stop_music(fade_out: bool = false) -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	if fade_out:
		fade_tween = create_tween().set_parallel(true)

		if track_a.playing:
			fade_tween.tween_property(track_a, "volume_linear", 0.0, fade_duration)\
				.set_ease(Tween.EASE_IN)
		if track_b.playing:
			fade_tween.tween_property(track_b, "volume_linear", 1.0, fade_duration)\
				.set_ease(Tween.EASE_OUT)

		fade_tween.chain().tween_callback(func():
			track_a.stop()
			track_b.stop()
			track_a.stream = null
			track_b.stream = null
		)
	else:
		track_a.stop()
		track_b.stop()
		track_a.stream = null
		track_b.stream = null
