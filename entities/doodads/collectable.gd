extends Area2D
class_name Collectable

signal picked_up(collectable: Collectable)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	picked_up.emit(self)
	queue_free()
