extends Area2D

@onready var bounds_shape: CollisionShape2D = $Bounds

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return

	var rect := _get_bounds_rect()

	var cam := get_viewport().get_camera_2d() as Cam
	cam.set_zone_limits(rect)
	print(rect)


func _get_bounds_rect() -> Rect2:
	if bounds_shape.shape is not RectangleShape2D:
		push_error("BoundsShape must use RectangleShape2D. Unless your monitor is a different shape..")
		return Rect2()

	var shape := bounds_shape.shape as RectangleShape2D

	var size := shape.size
	var center := bounds_shape.global_position

	return Rect2(center - size * 0.5, size)
