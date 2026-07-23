extends BaseLevel
## Level 03 — Top-down demo.
## Navigate a small maze to reach the GOAL zone. 8-directional movement.

const WALL_COLOR := Color(0.28, 0.30, 0.38)


func _build_level() -> void:
	# Outer border.
	build_solid(Vector2(640, 0), Vector2(1280, 40), WALL_COLOR)
	build_solid(Vector2(640, 720), Vector2(1280, 40), WALL_COLOR)
	build_solid(Vector2(0, 360), Vector2(40, 720), WALL_COLOR)
	build_solid(Vector2(1280, 360), Vector2(40, 720), WALL_COLOR)

	# Interior maze walls (forms a winding path).
	build_solid(Vector2(280, 200), Vector2(40, 320), WALL_COLOR)
	build_solid(Vector2(280, 540), Vector2(360, 40), WALL_COLOR)
	build_solid(Vector2(560, 180), Vector2(40, 280), WALL_COLOR)
	build_solid(Vector2(720, 320), Vector2(360, 40), WALL_COLOR)
	build_solid(Vector2(900, 460), Vector2(40, 240), WALL_COLOR)
	build_solid(Vector2(1080, 580), Vector2(360, 40), WALL_COLOR)

	# Player.
	var player := PlayerTopDown.new()
	player.position = Vector2(120, 120)
	add_child(player)

	# Win condition: reach the goal in the top-right corner.
	var objective := ReachGoalObjective.new()
	objective.goal_position = Vector2(1180, 100)
	objective.goal_size = Vector2(80, 80)
	add_child(objective)
