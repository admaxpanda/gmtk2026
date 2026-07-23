extends Node2D
## Test: PlayerTopDown controller.
## Verifies: 8-directional movement, diagonal normalization, collision with walls.
## Controls: WASD or arrows to move. R to reset position.

const WALL_COLOR := Color(0.28, 0.30, 0.38)

var _player: PlayerTopDown
var _status: Label


func _ready() -> void:
	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))
	add_child(SceneHelpers.make_label("TEST: PlayerTopDown", Vector2(40, 20), 28))
	add_child(SceneHelpers.make_label(
		"WASD or arrows to move (diagonals are normalized). R to reset position.",
		Vector2(40, 60), 16, Color(0.7, 0.7, 0.75)))

	# Outer border + a few interior walls.
	add_child(SceneHelpers.make_solid(Vector2(640, 0), Vector2(1280, 40), WALL_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(640, 720), Vector2(1280, 40), WALL_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(0, 360), Vector2(40, 720), WALL_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(1280, 360), Vector2(40, 720), WALL_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(480, 360), Vector2(40, 360), WALL_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(800, 200), Vector2(360, 40), WALL_COLOR))

	_player = PlayerTopDown.new()
	_player.position = Vector2(200, 360)
	add_child(_player)

	_status = SceneHelpers.make_label("", Vector2(40, 100), 16, Color(0.65, 0.85, 0.65))
	add_child(_status)

	_make_back_button()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var input_vec := Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down")
	)
	var speed: float = _player.velocity.length()
	_status.text = "input:     (%.2f, %.2f)  len=%.2f\nvelocity:  (%.1f, %.1f)  speed=%.1f\nposition:  (%.0f, %.0f)\n(max speed = 260, diagonals capped)" % [
		input_vec.x, input_vec.y, input_vec.length(),
		_player.velocity.x, _player.velocity.y, speed,
		_player.position.x, _player.position.y,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset"):
		_player.position = Vector2(200, 360)
		_player.velocity = Vector2.ZERO


func _make_back_button() -> void:
	var back_btn := SceneHelpers.make_button("← Back to Test Menu", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)
