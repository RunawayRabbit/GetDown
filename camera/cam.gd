extends Camera2D
class_name Cam

@export_category("Camera Movement")
@export var limit_transition_speed: float = 120.0
@export var look_ahead_distance: float = 80.0
@export_category("Camera Shake")
@export var shake_duration: float = 1.0
@export var shake_intensity:float = 16.0

var _target_rect:Rect2 = Rect2(Vector2.ZERO, Vector2.ONE)
var _current_rect:Rect2 = Rect2(Vector2.ZERO, Vector2.ONE)
var shake_tween: Tween = null

func _ready() -> void:
	_snap_camera_bounds()


func random_in_circle() -> Vector2:
	# why the fuck do i have to write this myself
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle)) * sqrt(randf())


## Experimenting with actually using variant.. but these arguments are floats. :D
func shake(duration = null, intensity = null):
	var _duration:float = duration if duration else shake_duration
	var _intensity:float = intensity if intensity else shake_intensity
	
	if shake_tween: shake_tween.kill()
	
	shake_tween = create_tween()
	shake_tween.tween_method(func(t:float):
		var displacement = random_in_circle() * _intensity * t
		offset = displacement
	, 1.0, 0.0, _duration)

func _snap_camera_bounds() -> void:
	_current_rect = _target_rect


func _process(delta: float) -> void:
	_current_rect.position.x = move_toward(_current_rect.position.x, _target_rect.position.x, delta*limit_transition_speed)
	_current_rect.position.y = move_toward(_current_rect.position.y, _target_rect.position.y, delta*limit_transition_speed)
	_current_rect.size.x = move_toward(_current_rect.size.x, _target_rect.size.x, delta*limit_transition_speed)
	_current_rect.size.y = move_toward(_current_rect.size.y, _target_rect.size.y, delta*limit_transition_speed)
	
	limit_left = round(_current_rect.position.x)
	limit_top = round(_current_rect.position.y)
	limit_right = round(_current_rect.end.x)
	limit_bottom = round(_current_rect.end.y)
	
	DebugDisplay.watch("Camera Bounds", func(): return _current_rect)
	
	if limit_left == floori(_target_rect.position.x) && \
	   limit_right == floori(_target_rect.end.x) && \
	   limit_top == floori(_target_rect.position.y) && \
	   limit_bottom == floori(_target_rect.end.y):
		_snap_camera_bounds()
		set_process(false)
	

func set_facing(direction: int) -> void:
	drag_horizontal_offset = direction * 10.0


func set_zone_limits(rect: Rect2, snap: bool = false) -> void:
	set_process(true)
	_target_rect = rect
	_target_rect.position = round(_target_rect.position)
	_target_rect.size = round(_target_rect.size)
	if snap: _snap_camera_bounds()
