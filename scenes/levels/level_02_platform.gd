extends BaseLevel
## Level 02 — Platformer demo.
## Run/jump across floating platforms to reach the GOAL zone.

const FLOOR_COLOR := Color(0.30, 0.32, 0.40)
const PLATFORM_COLOR := Color(0.40, 0.42, 0.50)


func _build_background() -> void:
	# Wider than viewport — level scrolls horizontally via Camera2D.
	var bg := ColorRect.new()
	bg.color = bg_color
	bg.size = Vector2(2400, 720)
	bg.position = Vector2(-100, 0)
	add_child(bg)


func _build_level() -> void:
	# Long ground stretching under the whole level.
	build_solid(Vector2(1100, 700), Vector2(2400, 40), FLOOR_COLOR)

	# Floating platforms forming a jumpable path to the goal.
	build_solid(Vector2(420, 560), Vector2(220, 28), PLATFORM_COLOR)
	build_solid(Vector2(720, 460), Vector2(220, 28), PLATFORM_COLOR)
	build_solid(Vector2(1060, 380), Vector2(220, 28), PLATFORM_COLOR)
	build_solid(Vector2(1420, 460), Vector2(220, 28), PLATFORM_COLOR)
	build_solid(Vector2(1780, 540), Vector2(280, 28), PLATFORM_COLOR)

	# Player + follow camera.
	var player := PlayerPlatformer.new()
	player.position = Vector2(150, 620)
	add_child(player)
	var cam := Camera2D.new()
	cam.position = Vector2(0, -100)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 2300
	cam.limit_bottom = 720
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)

	# Win condition: reach the goal at the far right.
	var objective := ReachGoalObjective.new()
	objective.goal_position = Vector2(2120, 620)
	objective.goal_size = Vector2(80, 80)
	add_child(objective)
