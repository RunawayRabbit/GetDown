extends CharacterBody2D
class_name Enemy

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var wavelength: float = 3.0
@export var amplitude: float = 10.0

var _base_y: float = 0.0
var _t: float = 0.0
var _is_dying: bool = false

func _ready() -> void:
	hurtbox.died.connect(on_died)
	_base_y = position.y


func _physics_process(delta: float) -> void:
	if _is_dying: return
	_t += delta * wavelength
	position.y = _base_y + sin(_t) * amplitude


func on_died() -> void:
	_is_dying = true
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	queue_free()
