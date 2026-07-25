extends BaseLevel
## Level 06 — Scatter test. Random-looking scattered obstacles on a bright bg.
## Used to verify thumbnail rendering.

func _build_level() -> void:
	# Bright background override.
	bg_color = Color(0.18, 0.22, 0.30)

	var obstacles: Array = [
		[Vector2(200, 150), Vector2(120, 60)],
		[Vector2(600, 300), Vector2(80, 200)],
		[Vector2(400, 550), Vector2(200, 40)],
		[Vector2(900, 200), Vector2(60, 160)],
		[Vector2(1050, 500), Vector2(150, 50)],
		[Vector2(150, 400), Vector2(100, 100)],
		[Vector2(750, 600), Vector2(180, 30)],
	]
	var color := Color(0.45, 0.55, 0.65)
	for obs in obstacles:
		build_solid(obs[0], obs[1], color)
