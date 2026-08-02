extends Area2D
class_name Collectable

@export var wavelength: float = 0.4
@export var amplitude: float = 2.0

signal picked_up(collectable: Collectable)

var _base_y: float = 0.0
var _t:float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_y = position.y


func _physics_process(delta: float) -> void:
	_t += delta / wavelength
	position.y = _base_y + sin(_t) * amplitude


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	picked_up.emit(self)
	queue_free()
