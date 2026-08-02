extends SwitchDoor
class_name SwitchDoorToggle

## Which state of this door's switch OPENS this door. The other will close it.
@export var opens_on: ToggleSwitch.State = ToggleSwitch.State.LEFT


func initialize(resume_after_golden: bool) -> void:
	if resume_after_golden and forced_open_on_golden_resume:
		gate.snap_open()
		return

	var flip_switch := _find_toggle_switch()
	if flip_switch and flip_switch.state == opens_on:
		gate.snap_open()
	else:
		gate.snap_closed()


func _find_toggle_switch() -> ToggleSwitch:
	for s in switches:
		if s is ToggleSwitch:
			return s
	return null


func _on_switch_activated(switch: Switch) -> void:
	var flip_switch := switch as ToggleSwitch
	if not flip_switch:
		return

	if flip_switch.state == opens_on:
		open()
	else:
		close()
