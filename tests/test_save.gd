extends Node2D
## Test: SaveManager (per-level persistence with direction-aware best times).
## Verifies: write/read completion, write/read best time (count-up = lower better,
## count-down = higher better), delete, first-record handling.
## Uses isolated test level IDs so it never pollutes real save data.

const TEST_ID_UP: String = "test_count_up"
const TEST_ID_DOWN: String = "test_count_down"

var _display: Label
var _event_log: Label
var _events: Array = []


func _ready() -> void:
	# Clean up any leftover test data from previous runs.
	SaveManager.delete_level_data(TEST_ID_UP)
	SaveManager.delete_level_data(TEST_ID_DOWN)

	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))
	add_child(SceneHelpers.make_label("TEST: SaveManager", Vector2(40, 20), 28))
	add_child(SceneHelpers.make_label(
		"Direction-aware best times: count-up = lower wins, count-down = higher wins. Isolated test IDs.",
		Vector2(40, 60), 16, Color(0.7, 0.7, 0.75)))

	_display = SceneHelpers.make_label("", Vector2(40, 100), 16, Color(0.65, 0.85, 0.65))
	add_child(_display)

	_event_log = SceneHelpers.make_label("", Vector2(40, 300), 14, Color(0.75, 0.75, 0.55))
	add_child(_event_log)

	# Count-up (lower is better) — seed a baseline of 12.5s, then try to beat it.
	_add_button("Seed count-up best = 12.5s", Vector2(40, 220), func():
		_save_best(TEST_ID_UP, 12.5, true))
	_add_button("Submit 10.0s (should BEAT)", Vector2(300, 220), func():
		_save_best(TEST_ID_UP, 10.0, true))
	_add_button("Submit 15.0s (should NOT beat)", Vector2(520, 220), func():
		_save_best(TEST_ID_UP, 15.0, true))

	# Count-down (higher is better) — seed a baseline of 30s left, then try to beat it.
	_add_button("Seed count-down best = 30s left", Vector2(40, 260), func():
		_save_best(TEST_ID_DOWN, 30.0, false))
	_add_button("Submit 35s left (should BEAT)", Vector2(300, 260), func():
		_save_best(TEST_ID_DOWN, 35.0, false))
	_add_button("Submit 25s left (should NOT beat)", Vector2(520, 260), func():
		_save_best(TEST_ID_DOWN, 25.0, false))

	_add_button("Mark both completed", Vector2(780, 220), func():
		SaveManager.set_level_completed(TEST_ID_UP, true)
		SaveManager.set_level_completed(TEST_ID_DOWN, true)
		_log("Marked both completed."))
	_add_button("Clear test data", Vector2(780, 260), func():
		SaveManager.delete_level_data(TEST_ID_UP)
		SaveManager.delete_level_data(TEST_ID_DOWN)
		_log("Cleared all test data."))

	var back_btn := SceneHelpers.make_button("← Back to Test Menu", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)

	_refresh_display()
	_log("Ready. Test data cleared on startup.")


func _save_best(level_id: String, time_val: float, lower_is_better: bool) -> void:
	var is_new: bool = SaveManager.set_best_time(level_id, time_val, lower_is_better)
	var direction: String = "lower-better" if lower_is_better else "higher-better"
	_log("set_best_time(%s, %.1f, %s) → new best = %s" % [level_id, time_val, direction, is_new])
	_refresh_display()


func _refresh_display() -> void:
	var lines: Array = []
	for id in [TEST_ID_UP, TEST_ID_DOWN]:
		var completed: bool = SaveManager.is_level_completed(id)
		var best: float = SaveManager.get_best_time(id)
		var best_str: String = "%.3f" % best if is_finite(best) else "(no record)"
		lines.append("%s:\n  completed = %s\n  best      = %s" % [id, completed, best_str])
	_display.text = "\n".join(lines)


func _log(msg: String) -> void:
	_events.append(msg)
	if _events.size() > 8:
		_events.pop_at(0)
	_event_log.text = "Event log:\n" + "\n".join(_events)


func _add_button(text: String, pos: Vector2, callback: Callable) -> void:
	var btn := SceneHelpers.make_button(text, pos)
	btn.custom_minimum_size = Vector2(220, 36)
	btn.pressed.connect(callback)
	add_child(btn)
