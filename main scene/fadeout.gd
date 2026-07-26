extends ColorRect

#TODO: No time to finish this, but it's currently a half-done refactor.
# There is code in UI_Shell that needs to not be there and be here instead.
# We also need to hold our own tween etc.

func fade(target_alpha: float, duration: float) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if target_alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, duration)
	await tween.finished
