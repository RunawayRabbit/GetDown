extends Area2D
class_name CamZone


@onready var bounds_shape: CollisionShape2D = $Bounds

var _cam: Cam = null


func _ready() -> void:
	add_to_group("cam_zones")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if bounds_shape and not bounds_shape.disabled:
		warnings.append("Make sure the 'Bounds' node is disabled in the editor, please. Otherwise CamZone will bug out.")

	if bounds_shape and not is_zero_approx(bounds_shape.rotation):
		warnings.append("Bounds shape is rotated. The camera don't do that.")

	if bounds_shape and bounds_shape.shape and not bounds_shape.shape is RectangleShape2D:
		warnings.append("Bounds shape must use a RectangleShape2D. Because your monitor isn't circular.")

	return warnings


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_apply_bounds()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# TODO: Rescan or maintain a stack? Going for the rescan approach. for now.
	for node in get_tree().get_nodes_in_group("cam_zones"):
		var zone := node as CamZone
		if not zone or zone == self:
			continue
		if zone.get_overlapping_bodies().has(body):
			zone._apply_bounds()
			return


	# Defaults
	var cam := _get_cam()
	if cam: cam.clear_zone_limits()


func _apply_bounds() -> void:
	var cam := _get_cam()
	var rect = _get_bounds_rect()

	if cam and rect != null:
		cam.set_zone_limits(rect)


# TODO: Unnecessary lazy instantiation.
func _get_cam() -> Cam:
	if not _cam:
		_cam = get_viewport().get_camera_2d() as Cam
	return _cam


func _get_bounds_rect() -> Variant:
	if not bounds_shape.shape is RectangleShape2D:
		push_error("%s: Bounds shape must use a RectangleShape2D." % name)
		return null

	var shape := bounds_shape.shape as RectangleShape2D
	var size := shape.size * bounds_shape.global_scale
	var center := bounds_shape.global_position

	return Rect2(center - size * 0.5, size)
