extends Camera2D
class_name Cam

@export_category("Camera Movement")
@export var limit_transition_speed: float = 120.0
@export var look_ahead_distance: float = 30.0
@export_category("Camera Shake")
@export var shake_duration: float = 1.0
@export var shake_intensity:float = 16.0

var _target_rect:Rect2 = Rect2(-600, -150, 1200, 300)
var _current_rect:Rect2 = _target_rect
var shake_tween: Tween = null

func _ready() -> void:
	_snap_to_target()


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

func _snap_to_target() -> void:
	_current_rect = _target_rect
	limit_left = round(_target_rect.position.x)
	limit_top = round(_target_rect.position.y)
	limit_right = round(_target_rect.end.x)
	limit_bottom = round(_target_rect.end.y)


func _process(delta: float) -> void:
	_current_rect.position.x = move_toward(_current_rect.position.x, _target_rect.position.x, delta*limit_transition_speed)
	_current_rect.position.y = move_toward(_current_rect.position.y, _target_rect.position.y, delta*limit_transition_speed)
	_current_rect.size.x = move_toward(_current_rect.size.x, _target_rect.size.x, delta*limit_transition_speed)
	_current_rect.size.y = move_toward(_current_rect.size.y, _target_rect.size.y, delta*limit_transition_speed)
	
	limit_left = round(_current_rect.position.x)
	limit_top = round(_current_rect.position.y)
	limit_right = round(_current_rect.end.x)
	limit_bottom = round(_current_rect.end.y)
		
	if limit_left == floori(_target_rect.position.x) && \
	   limit_right == floori(_target_rect.end.x) && \
	   limit_top == floori(_target_rect.position.y) && \
	   limit_bottom == floori(_target_rect.end.y):
		_snap_to_target()
		set_process(false)
	

func set_facing(direction: int) -> void:
	drag_horizontal_offset = direction * look_ahead_distance


func set_zone_limits(rect: Rect2, snap: bool = false) -> void:
	_target_rect = rect
	_target_rect.position = round(_target_rect.position)
	_target_rect.size = round(_target_rect.size)
	
	if snap:
		_snap_to_target()
	else:
		
		var viewport_size := get_viewport_rect().size / zoom
		var center := get_screen_center_position()
		_current_rect = Rect2(center - viewport_size * 0.5, viewport_size)
		
		limit_left = round(_current_rect.position.x)
		limit_top = round(_current_rect.position.y)
		limit_right = round(_current_rect.end.x)
		limit_bottom = round(_current_rect.end.y)
		
		set_process(true)
