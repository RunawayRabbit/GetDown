extends Area2D
class_name Switch

## Fires every time the player steps on it. Dumb as bricks. Logic elsewhere.
signal activated(switch: Switch)
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

## How long the button should wait before attempting to pop back up again.
@export var _popup_time: float = INF
var _is_depressed: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = false
	set_process(false)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		activated.emit(self)
		depress()
		if _popup_time != INF:
			await get_tree().create_timer(_popup_time).timeout
			set_process(true)
			

func _process(_delta: float) -> void:
	var overlaps := get_overlapping_bodies()
	for overlap in overlaps:
		var chara := overlap as CharacterBody2D
		if chara and chara.is_in_group("player"):
			return
	pop_up()
	set_process(false)

#TODO: Don't need all these null checks but they fine for now.
func depress() -> void:
	if _is_depressed == true: return
	_is_depressed = true
	if animated_sprite_2d and animated_sprite_2d.sprite_frames.has_animation("down"):
		animated_sprite_2d.play("down")

	
func pop_up() -> void:
	if _is_depressed == false: return
	_is_depressed = false
	if animated_sprite_2d and animated_sprite_2d.sprite_frames.has_animation("up"):
		animated_sprite_2d.play("up")
