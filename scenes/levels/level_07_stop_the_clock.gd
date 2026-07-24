extends BaseLevel
## Level 07 — Stop the Clock.
## A red button sits at screen center with a 2-decimal countdown. Click it when
## the countdown reaches 0.00 (within 0.25s) to win. Click too early = fail.
## Timer reaching 0 without a valid click = fail (BaseLevel default timed_out).


func _build_level() -> void:
	var objective := StopClockObjective.new()
	# Defaults: target_remaining=0.0, tolerance=0.25, button at (640,360) — screen center.
	add_child(objective)
