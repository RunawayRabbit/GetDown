extends Switch
class_name ToggleSwitch

enum State { NONE, LEFT, RIGHT }

## Starting state, before ever being hit.
@export var initial_state: State = State.LEFT

var state: State = State.NONE


func _ready() -> void:
	# INTENTIONALLY skipping the super() call. We do NOT want to wire up
	# our body_entered signals.
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	set_state(initial_state, true)

		
	
func set_state(new_state: State, snap_animation: bool = false):
	if state == new_state: return

	state = new_state
	var anim_name = &"left" if state == State.LEFT else &"right"
	if animated_sprite_2d.sprite_frames.has_animation(anim_name):
		animated_sprite_2d.play(anim_name)
		if snap_animation:
			animated_sprite_2d.frame = animated_sprite_2d.sprite_frames.get_frame_count(anim_name) - 1
		
	activated.emit(self)
		
func _on_area_entered(area: Area2D) -> void:
	# TODO: Using a group for this might be impractical, although it works.
	# Making Hitbox a class might be a better solution.
	if not area.is_in_group("player_attack"):
		return

	var attacker := area.get_parent()
	if not attacker:
		return

	set_state(State.LEFT if attacker.global_position.x > global_position.x else State.RIGHT)

	
