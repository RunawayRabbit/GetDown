extends Resource
class_name ImpactEffect

@export_category("SFX")
@export var sound: Array[AudioStream]
@export var pitch_variance: float = 0.08

@export_category("Particle")
@export var particles: Array[PackedScene]

@export_category("Screen Shake")
@export var screen_shake_intensity: float = 0.0
@export var screen_shake_duration: float = 0.0
