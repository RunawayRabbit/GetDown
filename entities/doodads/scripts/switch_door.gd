@abstract
extends Node2D
class_name SwitchDoor

## All of the switches that must be hit for this door to open.
@export var switches: Array[Switch]

## This door spawns opened after a golden feather death. True for all but some
## very specific edge cases, be careful as this is a source of softlocking.
@export var forced_open_on_golden_resume: bool = true

@onready var gate: DoorGate = $DoorGate

var is_open: bool:
	get: return gate.state == DoorGate.State.OPEN



func _ready() -> void:
	gate.snap_closed() # For testing, remove later.
	for s in switches:
		s.activated.connect(_on_switch_activated)


func initialize(resume_after_golden: bool) -> void:
	if resume_after_golden and forced_open_on_golden_resume:
		gate.snap_open()
	else:
		gate.snap_closed()


@abstract func _on_switch_activated(_switch: Switch) -> void


func open() -> void:
	gate.open()


func close() -> void:
	gate.close()
