extends Node2D

@onready var _speech_bubble: AnimatedSprite2D = $SpeechBubble
@onready var _area: Area2D = $Area2D

func _ready() -> void:
	set_physics_process(false)
	
	_speech_bubble.visible = false

	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("honk"):
		DialogueManager.start_next_dialogue()


func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("player"):
		_speech_bubble.visible = true
		_speech_bubble.play("default")
		set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	
	if body.is_in_group("player"):
		_speech_bubble.visible = false
		set_physics_process(false)
