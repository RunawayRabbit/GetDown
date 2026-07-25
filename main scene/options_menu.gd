extends Control
class_name OptionsMenu

signal closed

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var keybind_list: Container = %KeybindList

@onready var back_button: Button = %BackButton

var _listening_action: String = ""
var _keybind_buttons: Dictionary = {} # action_name -> Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0

	master_slider.value = Settings.get_bus_volume("Master")
	music_slider.value = Settings.get_bus_volume("Music")
	sfx_slider.value = Settings.get_bus_volume("SFX")

	master_slider.value_changed.connect(func(v): Settings.set_bus_volume("Master", v))
	music_slider.value_changed.connect(func(v): Settings.set_bus_volume("Music", v))
	sfx_slider.value_changed.connect(func(v): Settings.set_bus_volume("SFX", v))

	back_button.pressed.connect(func(): closed.emit())

	_populate_keybinds()


func _populate_keybinds() -> void:
	for child in keybind_list.get_children():
		child.queue_free()
	_keybind_buttons.clear()

	for action in Settings.get_rebindable_actions():
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = action.capitalize()
		label.custom_minimum_size.x = 160
		row.add_child(label)

		var button := Button.new()
		button.text = Settings.get_keybind_label(action)
		button.custom_minimum_size.x = 140
		button.pressed.connect(_on_rebind_pressed.bind(action, button))
		row.add_child(button)

		keybind_list.add_child(row)
		_keybind_buttons[action] = button


func _on_rebind_pressed(action: String, button: Button) -> void:
	_listening_action = action
	button.text = "Press any key…"


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if _listening_action != "":
		return

	if event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if _listening_action == "":
		return

	if not event is InputEventKey or not event.pressed:
		return

	var key_event := event as InputEventKey

	if key_event.physical_keycode == KEY_ESCAPE:
		_keybind_buttons[_listening_action].text = Settings.get_keybind_label(_listening_action)
		_listening_action = ""
		get_viewport().set_input_as_handled()
		return

	Settings.remap_key(_listening_action, key_event)
	_keybind_buttons[_listening_action].text = Settings.get_keybind_label(_listening_action)
	_listening_action = ""
	get_viewport().set_input_as_handled()
