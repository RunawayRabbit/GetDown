extends Area2D

## Music for this zone.
@export var zone_music: AudioStream
## Whether we fade in, or just start playing cold.
@export var fade_in: bool
## Whether we stop the current music first, let it fade out.
@export var stop_previous: bool


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and zone_music:
		if stop_previous: MusicManager.stop_music()
		MusicManager.play_music(zone_music, fade_in)
