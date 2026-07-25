extends BaseLevel
## Level 04 — Color Blocks test. A grid of colorful blocks with no win condition
## (used to verify thumbnail rendering).

func _build_level() -> void:
	var colors: Array = [
		Color(0.90, 0.30, 0.25),
		Color(0.25, 0.75, 0.40),
		Color(0.30, 0.50, 0.90),
		Color(0.95, 0.75, 0.20),
		Color(0.70, 0.35, 0.80),
	]
	var idx := 0
	for row in range(3):
		for col in range(5):
			build_solid(
				Vector2(160 + col * 200, 200 + row * 180),
				Vector2(140, 120),
				colors[idx % colors.size()]
			)
			idx += 1
