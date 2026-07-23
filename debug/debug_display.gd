extends CanvasLayer

@onready var label := Label.new()

var watches:Dictionary = {}

func _ready():
	layer = 1000

	label.position = Vector2(5, 5)
	label.add_theme_font_size_override("font_size", 8)
	label.modulate = Color(1, 1, 1)

	add_child(label)


func _process(_delta):
	var keys := watches.keys()
	keys.sort()

	var text := ""

	for key in keys:
		text += "%s: %s\n" % [key, watches[key].call()]

	label.text = text


func watch(key: String, lambda: Callable):
	watches[key] = lambda


func remove_display(key):
	watches.erase(key)
