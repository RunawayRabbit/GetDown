extends Control
class_name TimerDisplay

@onready var _timer_text: Label = $HBoxContainer/TimerText
@onready var animation_player: AnimationPlayer = $AnimationPlayer


var _timer: Timer = null
var _last_seen_time: String = ""


func start_timer(timer: Timer) -> void:
	visible = true
	_timer = timer
	set_process(true)
	animation_player.play("go")
	
	
func end_timer() -> void:
	visible = false
	_timer = null
	set_process(false)


func freeze_timer() -> void:
	set_process(false)

	# hacky but i don't see a better way. =(
	for i in range(10):
		visible = not visible
		await get_tree().create_timer(0.3).timeout

	_timer = null
	visible = false

func _process(_delta: float) -> void:
	if _timer: #and _timer.time_left > 0.0:
		_last_seen_time = String.num(_timer.time_left, 2)
		_timer_text.text = _last_seen_time
