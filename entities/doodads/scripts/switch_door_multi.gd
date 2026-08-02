extends SwitchDoor
class_name SwitchDoorSequence


@export var sequence_time_limit: float = 5.0
@onready var sequence_timer: Timer = $Timer
var _activated_switches: Array[Switch] = []


func _ready() -> void:
	super._ready()
	sequence_timer.one_shot = true
	sequence_timer.timeout.connect(_on_sequence_timeout)


func _on_switch_activated(switch: Switch) -> void:
	if is_open:
		return

	if _activated_switches.is_empty():
		sequence_timer.start(sequence_time_limit)

	if not _activated_switches.has(switch):
		_activated_switches.append(switch)

	if _activated_switches.size() >= switches.size():
		sequence_timer.stop()
		_activated_switches.clear()
		open()


func _on_sequence_timeout() -> void:
	for switch in _activated_switches:
		switch.pop_up()
	_activated_switches.clear()
	
