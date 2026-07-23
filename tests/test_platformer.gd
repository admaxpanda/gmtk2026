extends Node2D
## Test: PlayerPlatformer controller.
## Verifies: horizontal movement, gravity, jump, coyote time, jump buffering,
## variable jump height. Real-time state display for diagnostics.
## Controls: A/D or arrows to move, Space to jump. R to reset position.

const FLOOR_COLOR := Color(0.30, 0.32, 0.40)
const PLATFORM_COLOR := Color(0.40, 0.42, 0.50)

var _player: PlayerPlatformer
var _status: Label


func _ready() -> void:
	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))
	add_child(SceneHelpers.make_label("TEST: PlayerPlatformer", Vector2(40, 20), 28))
	add_child(SceneHelpers.make_label(
		"A/D or arrows to move. Space to jump (hold for higher, tap for short). R to reset.",
		Vector2(40, 60), 16, Color(0.7, 0.7, 0.75)))

	# Floor + a few platforms to test jumping.
	add_child(SceneHelpers.make_solid(Vector2(640, 700), Vector2(1280, 40), FLOOR_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(400, 560), Vector2(220, 28), PLATFORM_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(760, 460), Vector2(220, 28), PLATFORM_COLOR))
	add_child(SceneHelpers.make_solid(Vector2(1080, 380), Vector2(220, 28), PLATFORM_COLOR))

	_player = PlayerPlatformer.new()
	_player.position = Vector2(200, 620)
	add_child(_player)

	_status = SceneHelpers.make_label("", Vector2(40, 100), 16, Color(0.65, 0.85, 0.65))
	add_child(_status)

	_make_back_button()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_status.text = "velocity:        (%.1f, %.1f)\non_floor:        %s\ncoyote_remain:   %.3fs\nbuffer_remain:   %.3fs\njump_held:       %s\nposition:        (%.0f, %.0f)" % [
		_player.velocity.x, _player.velocity.y,
		_player.is_on_floor(),
		_player.get_coyote_remaining(),
		_player.get_jump_buffer_remaining(),
		_player.is_jump_held(),
		_player.position.x, _player.position.y,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset"):
		_player.position = Vector2(200, 620)
		_player.velocity = Vector2.ZERO


func _make_back_button() -> void:
	var back_btn := SceneHelpers.make_button("← Back to Test Menu", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)
