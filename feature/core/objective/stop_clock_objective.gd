class_name StopClockObjective
extends LevelObjective
## Win condition: click the red button when the countdown reaches a target
## remaining time (within `tolerance`). A 2-decimal label on the button shows
## the live remaining time so the player can time the click.
##
## Click within tolerance of `target_remaining` to win. Click too early (or
## outside the window) fails. If the countdown reaches 0 without a valid click,
## BaseLevel's timed_out handler fails the level automatically (it has not been
## completed, so _on_timer_timed_out forwards a "Time's up!" failure).

@export var target_remaining: float = 0.0
@export var tolerance: float = 0.25
@export var button_position: Vector2 = Vector2(640, 360)
@export var button_size: Vector2 = Vector2(220, 220)
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var label_text_color: Color = Color(1.0, 1.0, 1.0)

var _button: Area2D
var _time_label: Label


func _ready() -> void:
	_button = Area2D.new()
	_button.name = "StopButton"
	_button.position = button_position
	_button.input_pickable = true
	_button.collision_layer = 1 << 3  # draggable layer — reuse for clickables
	_button.collision_mask = 0
	_button.monitoring = false
	_button.monitorable = false

	var rect := ColorRect.new()
	rect.size = button_size
	rect.color = button_color
	rect.position = -button_size * 0.5
	_button.add_child(rect)

	_time_label = Label.new()
	_time_label.text = "%.2f" % target_remaining
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.size = button_size
	_time_label.position = -button_size * 0.5
	_time_label.add_theme_font_size_override("font_size", 48)
	_time_label.add_theme_color_override("font_color", label_text_color)
	_button.add_child(_time_label)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = button_size
	col.shape = shape
	_button.add_child(col)

	_button.input_event.connect(_on_input_event)
	LevelTimer.tick.connect(_on_tick)
	add_child(_button)

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
	var remaining: float = LevelTimer.get_remaining()
	var err: float = abs(remaining - target_remaining)
	if err <= tolerance:
		_complete()
	else:
		_fail("Stopped at %.2fs — click within %.2fs of %.2f." % [remaining, tolerance, target_remaining])


func get_progress_text() -> String:
	if not LevelTimer.is_countdown():
		return ""
	return "%.2fs left" % LevelTimer.get_remaining()


func get_progress_ratio() -> float:
	return 1.0 if _is_completed else 0.0
