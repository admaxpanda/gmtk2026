extends Node2D
## Test: LevelTimer (universal per-level timer with COUNT_UP / COUNT_DOWN modes).
## Verifies: start, tick, pause/resume, stop, reset, timed_out signal.
## Buttons start the timer in each mode; Space toggles pause; R resets.

var _display: Label
var _event_log: Label
var _events: Array = []


func _ready() -> void:
	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))
	add_child(SceneHelpers.make_label("TEST: LevelTimer (Count Up / Count Down)", Vector2(40, 20), 28))
	add_child(SceneHelpers.make_label(
		"Buttons start the timer. Space = pause/resume. R = reset. Watch the timed_out event at 0.",
		Vector2(40, 60), 16, Color(0.7, 0.7, 0.75)))

	_display = SceneHelpers.make_label("", Vector2(40, 100), 18, Color(0.65, 0.85, 0.65))
	add_child(_display)

	_event_log = SceneHelpers.make_label("", Vector2(40, 280), 14, Color(0.75, 0.75, 0.55))
	add_child(_event_log)

	# Control buttons
	_add_button("Start Count-Up", Vector2(40, 220), func(): LevelTimer.start("test_timer", LevelTimer.Mode.COUNT_UP))
	_add_button("Start Count-Down 5s", Vector2(220, 220), func(): LevelTimer.start("test_timer", LevelTimer.Mode.COUNT_DOWN, 5.0))
	_add_button("Start Count-Down 30s", Vector2(440, 220), func(): LevelTimer.start("test_timer", LevelTimer.Mode.COUNT_DOWN, 30.0))
	_add_button("Pause/Resume (Space)", Vector2(680, 220), _toggle_pause)
	_add_button("Reset (R)", Vector2(880, 220), func(): LevelTimer.reset_timer())

	var back_btn := SceneHelpers.make_button("← Back to Test Menu", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)

	LevelTimer.tick.connect(_on_tick)
	LevelTimer.timed_out.connect(_on_timed_out)
	_log("Ready. Press a button to start.")


func _add_button(text: String, pos: Vector2, callback: Callable) -> void:
	var btn := SceneHelpers.make_button(text, pos)
	btn.pressed.connect(callback)
	add_child(btn)


func _toggle_pause() -> void:
	if LevelTimer.is_running():
		LevelTimer.pause_timer()
		_log("Paused.")
	elif not LevelTimer.has_timed_out():
		LevelTimer.resume_timer()
		_log("Resumed.")


func _on_tick(_t: float) -> void:
	var mode_str: String = "COUNT_DOWN" if LevelTimer.is_countdown() else "COUNT_UP"
	_display.text = "mode:        %s\nelapsed:     %.3fs\nremaining:   %.3fs\ndisplay:     %.3fs\nrunning:     %s\ntimed_out:   %s" % [
		mode_str,
		LevelTimer.get_elapsed(),
		LevelTimer.get_remaining(),
		LevelTimer.get_display_time(),
		LevelTimer.is_running(),
		LevelTimer.has_timed_out(),
	]


func _on_timed_out() -> void:
	_log(">>> TIMED OUT signal fired! Timer frozen at 0.")


func _log(msg: String) -> void:
	_events.append(msg)
	if _events.size() > 8:
		_events.pop_at(0)
	_event_log.text = "Event log:\n" + "\n".join(_events)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset"):
		LevelTimer.reset_timer()
		_log("Reset.")
	elif event.is_action_pressed(&"jump"):
		_toggle_pause()
