class_name Level04NegativeSign
extends BaseLevel
## Level 4 — Negative Sign.
## A blue negative sign appears before the timer.
## When present: timer shows negative values.
## When removed: timer shows positive values.
## Click the button when timer shows 0.00.


func _ready() -> void:
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := NegativeSignObjective.new()
	add_child(objective)