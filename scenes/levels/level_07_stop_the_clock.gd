extends BaseLevel
## Level 07 — Stop the Clock.
## A red button sits at screen center with a 2-decimal countdown. Click it when
## the countdown reaches 0.00 (within 0.25s) to win. Click too early = fail.
## Timer reaching 0 without a valid click = fail (BaseLevel default timed_out).


func _ready() -> void:
	# Fill the 1920x1080 viewport (BaseLevel defaults bg_size to 1280x720).
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := StopClockObjective.new()
	# Defaults: target_remaining=0.0, tolerance=0.25, button at (960,540) — viewport center.
	add_child(objective)
