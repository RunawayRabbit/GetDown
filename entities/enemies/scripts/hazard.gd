extends Area2D
class_name Hazard

@export var damage: int = 999

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		(area as Hurtbox).take_damage(damage, self)
