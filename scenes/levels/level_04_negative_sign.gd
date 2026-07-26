class_name Level04NegativeSign
extends BaseLevel
## Level 4 — Negative Sign.
## A blue negative sign appears before the timer (draggable object, not a sign on the number).
## When present: timer counts UP as a plain number starting at 1 (1 → 2 → ... → 10) — a deception.
## When removed: timer counts DOWN (10 → 9 → ... → 0) — the true countdown.
## Click the button when the timer shows 0.00 (only after removing the sign).


func _ready() -> void:
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := NegativeSignObjective.new()
	add_child(objective)