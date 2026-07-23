extends CharacterBody2D
class_name Enemy

@onready var hurtbox: Hurtbox = $Hurtbox

func _ready() -> void:
	hurtbox.damaged.connect(on_damaged)
	hurtbox.died.connect(on_died)
	print("Hello. I'm %s." % name)


func on_damaged(amount: int, source: Node2D) -> void:
	print("%s hit me for %s damage." % [source.name, amount])


func on_died() -> void:
	print("%s fucking DIED." % name)
