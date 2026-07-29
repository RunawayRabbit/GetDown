extends Node

@export var pool_size: int = 8

var _stream_players: Array[AudioStreamPlayer2D] = []
var _next_player: int = 0


func _ready() -> void:
	for i in pool_size:
		var player := AudioStreamPlayer2D.new()
		player.bus = "SFX" # Same bus the options menu's volume slider controls.
		add_child(player)
		_stream_players.append(player)


func play(effect: ImpactEffect, global_pos: Vector2) -> void:
	if not effect:
		return

	var variance := effect.pitch_variance
	var sound := _pick(effect.sound) as AudioStream
	if sound:
		_play_sound(sound, global_pos, variance)

	var particles := _pick(effect.particles) as PackedScene
	if particles:
		_play_particles(particles, global_pos)

	if effect.screen_shake_intensity > 0.0:
		var cam := get_viewport().get_camera_2d() as Cam
		if cam:
			cam.shake(effect.screen_shake_duration, effect.screen_shake_intensity)

func _pick(options: Array) -> Variant:
	if options.is_empty():
		return null
	return options[randi() % options.size()]


## Round-robin, no checking. "Good enough", just add more channels.
func _play_sound(stream: AudioStream, global_pos: Vector2, variance: float) -> void:
	if _stream_players.is_empty():
		return

	var player := _stream_players[_next_player]
	_next_player = (_next_player + 1) % _stream_players.size()

	player.global_position = global_pos
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-variance, variance)
	player.play()


func _play_particles(scene: PackedScene, global_pos: Vector2) -> void:
	var particles = scene.instantiate()
	add_child(particles)
	particles.global_position = global_pos
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
