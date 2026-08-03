extends Node

const SETTINGS_PATH := "user://settings.cfg"
const BUS_NAMES := ["Master", "Music", "SFX"]

signal volume_changed(bus_name: String, linear_value: float)
signal keybind_changed(action: String)
signal timer_scale_changed(scale: float)
signal shake_intensity_changed(intensity: float)

var _config := ConfigFile.new()

var _timer_scale: float = 1.0
var _shake_intensity: float = 1.0


func _ready() -> void:
	_config.load(SETTINGS_PATH) # Error ignored on purpose - missing file just means first run.
	_apply_saved_volumes()
	_apply_saved_keybinds()
	_apply_saved_accessibility()


# --- Audio ----

func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("No audio bus named '%s'." % bus_name)
		return

	AudioServer.set_bus_volume_linear(idx, linear_value)

	_config.set_value("audio", bus_name, linear_value)
	_config.save(SETTINGS_PATH)
	volume_changed.emit(bus_name, linear_value)


func _apply_saved_volumes() -> void:
	for bus_name in BUS_NAMES:
		if _config.has_section_key("audio", bus_name):
			set_bus_volume(bus_name, _config.get_value("audio", bus_name))


# --- Keybinds ----

func get_rebindable_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in InputMap.get_actions():
		var action_name := String(action)
		if action_name.begins_with("ui_"):
			continue
		actions.append(action_name)
	actions.sort()
	return actions


func get_keybind_label(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).as_text_physical_keycode()
	return "-"


func remap_key(action: String, event: InputEventKey) -> void:
	_apply_key_binding(action, event)

	_config.set_value("keybinds", action, event.physical_keycode)
	_config.save(SETTINGS_PATH)
	keybind_changed.emit(action)


func _apply_key_binding(action: String, event: InputEventKey) -> void:
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey:
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, event)


func _apply_saved_keybinds() -> void:
	if not _config.has_section("keybinds"):
		return

	for action in _config.get_section_keys("keybinds"):
		if not InputMap.has_action(action):
			continue # Project's input map changed since this save - skip stale entries.

		var keycode: int = _config.get_value("keybinds", action)
		var event := InputEventKey.new()
		event.physical_keycode = keycode as Key
		_apply_key_binding(action, event)


# --- Accessibility -----

func get_timer_scale() -> float:
	return _timer_scale


func set_timer_scale(scale: float) -> void:
	_timer_scale = scale

	# TODO: Potentially unnecessary string "inf". Check how Godot does this kind of serialization.
	@warning_ignore("incompatible_ternary")
	_config.set_value("accessibility", "timer_scale", "inf" if is_inf(scale) else scale)
	_config.save(SETTINGS_PATH)
	timer_scale_changed.emit(scale)


func get_shake_intensity() -> float:
	return _shake_intensity


func set_shake_intensity(intensity: float) -> void:
	_shake_intensity = clampf(intensity, 0.0, 1.0)
	_config.set_value("accessibility", "shake_intensity", _shake_intensity)
	_config.save(SETTINGS_PATH)
	shake_intensity_changed.emit(_shake_intensity)


func _apply_saved_accessibility() -> void:
	if _config.has_section_key("accessibility", "timer_scale"):
		var raw = _config.get_value("accessibility", "timer_scale")
		_timer_scale = INF if raw == "inf" else float(raw)

	if _config.has_section_key("accessibility", "shake_intensity"):
		_shake_intensity = _config.get_value("accessibility", "shake_intensity")
