extends SwitchDoor
class_name SwitchDoorTimed

@export var close_delay: float = 3.0

@onready var close_timer: Timer = $Timer


func _ready() -> void:
	super._ready()
	close_timer.one_shot = true
	close_timer.timeout.connect(close)


func _on_switch_activated(_switch: Switch) -> void:
	open()
	close_timer.start(close_delay)
