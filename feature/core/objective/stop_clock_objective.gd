class_name StopClockObjective
extends LevelObjective
## Win condition: click the red button when the countdown reaches a target
## remaining time (within `tolerance`). A 2-decimal label ABOVE the button
## shows the live remaining time so the player can time the click.
##
## Click within tolerance of `target_remaining` to win. Click too early (or
## outside the window) fails. If the countdown reaches 0 without a valid click,
## BaseLevel's timed_out handler fails the level automatically (it has not been
## completed, so _on_timer_timed_out forwards a "Time's up!" failure).

@export var target_remaining: float = 0.0
@export var tolerance: float = 0.25
@export var button_position: Vector2 = Vector2(960, 540)  # center of 1920x1080 viewport
@export var button_radius: float = 110.0
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var label_text_color: Color = Color(1.0, 1.0, 1.0)
@export var trash_bin_position: Vector2 = Vector2(1720, 930)  # Bottom-right corner

var _button: Area2D
var _time_label: Label


func _ready() -> void:
	_button = Area2D.new()
	_button.name = "StopButton"
	_button.position = button_position
	_button.input_pickable = true
	_button.collision_layer = 1 << 3  # clickable
	_button.collision_mask = 0
	_button.monitoring = false
	_button.monitorable = false

	# Round red button — Polygon2D is a Node2D, so no mouse_filter hazard
	# (unlike a ColorRect Control child of an Area2D).
	var circle := Polygon2D.new()
	circle.polygon = _make_circle(button_radius, 48)
	circle.color = button_color
	_button.add_child(circle)

	# Countdown label, positioned ABOVE the button (not on it).
	_time_label = Label.new()
	_time_label.text = ""
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 64)
	_time_label.add_theme_color_override("font_color", label_text_color)
	_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_label.size = Vector2(button_radius * 2.0, 80.0)
	_time_label.position = Vector2(-button_radius, -button_radius - 90.0)
	_button.add_child(_time_label)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = button_radius
	col.shape = shape
	_button.add_child(col)

	_button.input_event.connect(_on_input_event)
	LevelTimer.tick.connect(_on_tick)
	add_child(_button)

	# Decorative trash bin (same as Level 2, but non-functional)
	var trash_bin := TrashBin.new()
	trash_bin.position = trash_bin_position
	trash_bin.is_functional = false  # Decorative only
	add_child(trash_bin)

	# F6/dev support: if LevelManager hasn't adopted this scene (standalone
	# run via F6), ask it to adopt us so complete/fail/timed_out work. In
	# normal play, LevelManager.load_level() already set the context before
	# this scene loaded, so this is a no-op.
	if not _is_preview() and LevelManager.get_current_level_id() == "":
		var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
		LevelManager.begin_dev_test(level_id)

	# Initial display (timer is now running in both F6 and normal play).
	_time_label.text = "%.2f" % max(LevelTimer.get_display_time(), 0.0)
	_emit_progress()


func _on_tick(display_time: float) -> void:
	_time_label.text = "%.2f" % max(display_time, 0.0)
	_emit_progress()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click()


func _handle_click() -> void:
	if _is_completed or _is_failed:
		return
	# timed_out fails the level via BaseLevel/LevelManager, which bypasses
	# _fail() — so _is_failed stays false here. Block the late click
	# explicitly. A legitimate same-frame click at ~0 happens in the input
	# flush before LevelTimer._process, so has_timed_out() is still false.
	if LevelTimer.has_timed_out():
		return
	var remaining: float = LevelTimer.get_remaining()
	var err: float = abs(remaining - target_remaining)
	if err <= tolerance:
		# Snap the countdown display to 0.00 on a successful stop.
		_time_label.text = "0.00"
		_complete()
	else:
		_fail("Too early!")


func get_progress_text() -> String:
	if not LevelTimer.is_countdown():
		return ""
	return "%.2fs left" % LevelTimer.get_remaining()


func get_progress_ratio() -> float:
	return 1.0 if _is_completed else 0.0


# --- Helpers ---

func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _is_preview() -> bool:
	# True when rendered inside a SubViewport (level_select thumbnail capture).
	var p := get_parent()
	while p != null:
		if p is SubViewport:
			return true
		p = p.get_parent()
	return false
