extends BaseLevel
## Level 05 — Narrow Path test. A winding corridor made of walls.
## Used to verify thumbnail rendering.

const WALL_COLOR := Color(0.35, 0.20, 0.15)
const FLOOR_COLOR := Color(0.55, 0.50, 0.40)

func _build_level() -> void:
	# Floor background under the corridor.
	var floor_rect := ColorRect.new()
	floor_rect.color = FLOOR_COLOR
	floor_rect.size = Vector2(1280, 720)
	floor_rect.position = Vector2.ZERO
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)

	# Top and bottom walls creating a winding path.
	build_solid(Vector2(320, 200), Vector2(960, 40), WALL_COLOR)
	build_solid(Vector2(640, 440), Vector2(640, 40), WALL_COLOR)
	build_solid(Vector2(960, 340), Vector2(640, 40), WALL_COLOR)

	# Left and right boundary walls.
	build_solid(Vector2(40, 360), Vector2(40, 720), WALL_COLOR)
	build_solid(Vector2(1240, 360), Vector2(40, 720), WALL_COLOR)
