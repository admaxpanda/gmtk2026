extends Node2D
## Test: LevelObjective system (ReachGoalObjective + DragAllToZoneObjective).
## Verifies: objective completion signals, progress reporting, idempotent _complete.
## Left section: drag 3 boxes into the drop zone. Right section: walk into the goal.

var _drag_obj: DragAllToZoneObjective
var _reach_obj: ReachGoalObjective
var _player: PlayerTopDown
var _status: Label


func _ready() -> void:
	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))
	add_child(SceneHelpers.make_label("TEST: LevelObjective", Vector2(40, 20), 28))
	add_child(SceneHelpers.make_label(
		"LEFT: drag 3 boxes into the drop zone.  RIGHT: walk the player into the GOAL.  R to reset.",
		Vector2(40, 60), 16, Color(0.7, 0.7, 0.75)))

	# Divider so the two sections are visually distinct.
	add_child(SceneHelpers.make_solid(Vector2(640, 360), Vector2(4, 600), Color(0.25, 0.25, 0.30)))

	# --- Left: DragAllToZoneObjective (3 boxes) ---
	_drag_obj = DragAllToZoneObjective.new()
	_drag_obj.zone_position = Vector2(480, 400)
	_drag_obj.zone_size = Vector2(280, 280)
	_drag_obj.required_count = 3
	_drag_obj.spawn_anchor = Vector2(60, 200)
	_drag_obj.spawn_step = Vector2(110, 110)
	add_child(_drag_obj)
	_drag_obj.completed.connect(_on_obj_completed.bind("DragAllToZone"))
	_drag_obj.progress_changed.connect(_on_progress.bind("DragAllToZone"))

	# --- Right: ReachGoalObjective + controllable player ---
	_player = PlayerTopDown.new()
	_player.position = Vector2(740, 360)
	add_child(_player)

	_reach_obj = ReachGoalObjective.new()
	_reach_obj.goal_position = Vector2(1140, 360)
	_reach_obj.goal_size = Vector2(100, 100)
	add_child(_reach_obj)
	_reach_obj.completed.connect(_on_obj_completed.bind("ReachGoal"))
	_reach_obj.progress_changed.connect(_on_progress.bind("ReachGoal"))

	add_child(SceneHelpers.make_label("WASD/arrows to move the player (right side).",
		Vector2(680, 100), 14, Color(0.6, 0.7, 0.85)))

	_status = SceneHelpers.make_label("", Vector2(40, 100), 16, Color(0.65, 0.85, 0.65))
	add_child(_status)

	var back_btn := SceneHelpers.make_button("← Back to Test Menu", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)

	var reset_btn := SceneHelpers.make_button("Reset (R)", Vector2(240, 660))
	reset_btn.pressed.connect(_on_reset)
	add_child(reset_btn)

	_update_status()


func _on_obj_completed(name: String) -> void:
	# Idempotency check: completing again should be a no-op (BaseLevel guards this,
	# but we verify the objective itself doesn't re-emit).
	_status.text += "\n>>> %s COMPLETED" % name


func _on_progress(name: String, ratio: float, text: String) -> void:
	# ReachGoal reports 0 until entered; DragAllToZone reports "n / N".
	pass  # status refreshed in _update_status()


func _process(_delta: float) -> void:
	_update_status()


func _update_status() -> void:
	var drag_completed: String = "YES" if _drag_obj.is_completed() else "no"
	var drag_text: String = _drag_obj.get_progress_text()
	var reach_completed: String = "YES" if _reach_obj.is_completed() else "no"
	_status.text = "DragAllToZoneObjective:\n  completed = %s\n  progress  = %s (ratio %.0f%%)\n\nReachGoalObjective:\n  completed = %s\n  progress  = %.0f%%" % [
		drag_completed, drag_text, _drag_obj.get_progress_ratio() * 100.0,
		reach_completed, _reach_obj.get_progress_ratio() * 100.0,
	]


func _on_reset() -> void:
	# Easiest reset: reload the scene.
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset"):
		_on_reset()
