extends Collectable
class_name GoldenFeather

func _ready() -> void:
	super._ready()
	#set_locked(true)
	set_locked(false)

func set_locked(locked: bool) -> void:
	visible = not locked
	monitoring = not locked
	set_deferred("monitorable", not locked)
