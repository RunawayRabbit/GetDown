extends Camera2D
class_name Cam

@export_category("Camera Movement")
@export var limit_transition_speed: float = 120.0
@export var look_ahead_distance: float = 30.0
@export var default_rect: Rect2 = Rect2(-100000, -100000, 200000, 200000)

@export_category("Camera Shake")
@export var shake_duration: float = 1.0
@export var shake_intensity:float = 16.0

var _target_rect: Rect2 = default_rect
var _current_rect: Rect2 = default_rect
var shake_tween: Tween = null

func _ready() -> void:
	_snap_to_target()


func random_in_circle() -> Vector2:
	# why the fuck do i have to write this myself
	var angle = randf() * TAU
	return Vector2(cos(angle), sin(angle)) * sqrt(randf())


## Experimenting with actually using variant.. but these arguments are floats. :D
func shake(duration = null, intensity = null):
	var _duration:float = duration if duration != null else shake_duration
	var _intensity:float = (intensity if intensity != null else shake_intensity) * Settings.get_shake_intensity()
	
	if shake_tween: shake_tween.kill()
	
	shake_tween = create_tween()
	shake_tween.tween_method(func(t:float):
		var displacement = random_in_circle() * _intensity * t
		offset = displacement
	, 1.0, 0.0, _duration)


func _snap_to_target() -> void:
	_current_rect = _target_rect
	_apply_current_rect()


func _apply_current_rect() -> void:
	limit_left = round(_current_rect.position.x)
	limit_top = round(_current_rect.position.y)
	limit_right = round(_current_rect.end.x)
	limit_bottom = round(_current_rect.end.y)


func _process(delta: float) -> void:
	_current_rect.position.x = move_toward(_current_rect.position.x, _target_rect.position.x, delta * limit_transition_speed)
	_current_rect.position.y = move_toward(_current_rect.position.y, _target_rect.position.y, delta * limit_transition_speed)
	_current_rect.size.x = move_toward(_current_rect.size.x, _target_rect.size.x, delta * limit_transition_speed)
	_current_rect.size.y = move_toward(_current_rect.size.y, _target_rect.size.y, delta * limit_transition_speed)

	_apply_current_rect()

	if limit_left == floori(_target_rect.position.x) and \
	   limit_right == floori(_target_rect.end.x) and \
	   limit_top == floori(_target_rect.position.y) and \
	   limit_bottom == floori(_target_rect.end.y):
		_snap_to_target()
		set_process(false)


func set_facing(direction: int) -> void:
	drag_horizontal_offset = direction * look_ahead_distance


func set_zone_limits(rect: Rect2, snap: bool = false) -> void:
	_target_rect = Rect2(round(rect.position), round(rect.size))

	if snap:
		_snap_to_target()
		return

	var viewport_size := get_viewport_rect().size / zoom
	var center := get_screen_center_position()
	_current_rect = Rect2(center - viewport_size * 0.5, viewport_size)

	_apply_current_rect()
	set_process(true)


## Reverts to default_rect - call this when the player is in zero CamZones.
func clear_zone_limits(snap: bool = false) -> void:
	set_zone_limits(default_rect, snap)
