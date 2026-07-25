extends Node

const SETTINGS_PATH := "user://settings.cfg"
const BUS_NAMES := ["Master", "Music", "SFX"]

signal volume_changed(bus_name: String, linear_value: float)
signal keybind_changed(action: String)

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(SETTINGS_PATH) # Error ignored on purpose - missing file just means first run.
	_apply_saved_volumes()
	_apply_saved_keybinds()


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

	AudioServer.set_bus_volume_db(idx, linear_to_db(linear_value))

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
