class_name NegativeSignObjective
extends LevelObjective
## Level 4 objective: Negative Sign.
## - A blue negative sign appears before the timer
## - When sign present: timer shows negative values increasing in magnitude (0 → -1 → -2...)
## - When sign removed: timer shows positive countdown (10 → 9 → 8... → 0)
## - Win condition: click the button when actual time reaches 0

@export var button_position: Vector2 = Vector2(960, 540)
@export var button_radius: float = 110.0
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var sign_position: Vector2 = Vector2(720, 50)  # Left of timer
@export var trash_bin_position: Vector2 = Vector2(1720, 930)
@export var time_limit: float = 10.0

var _button: Area2D
var _time_label: Label
var _negative_sign: NegativeSign
var _trash_bin: TrashBin
var _is_negative_mode: bool = true
var _elapsed_time: float = 0.0


func _ready() -> void:
	_build_trash_bin()
	_build_negative_sign()
	_build_button()
	_connect_timer()

	# F6 dev support
	if LevelManager.get_current_level_id() == "":
		var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
		LevelManager.begin_dev_test(level_id)

	_emit_progress()


func _build_button() -> void:
	_button = Area2D.new()
	_button.name = "ClickButton"
	_button.position = button_position
	_button.input_pickable = true
	_button.collision_layer = 1 << 3
	_button.collision_mask = 0
	_button.monitoring = false
	_button.monitorable = false

	# Round button visual
	var circle := Polygon2D.new()
	circle.polygon = _make_circle(button_radius, 48)
	circle.color = button_color
	_button.add_child(circle)

	# Time label above button
	_time_label = Label.new()
	_time_label.text = "0.00"
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 48)
	_time_label.add_theme_color_override("font_color", Color.WHITE)
	_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_label.size = Vector2(200, 60)
	_time_label.position = Vector2(-100, -button_radius - 80)
	_button.add_child(_time_label)

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = button_radius
	col.shape = shape
	_button.add_child(col)

	_button.input_event.connect(_on_button_input)
	add_child(_button)


func _build_negative_sign() -> void:
	_negative_sign = NegativeSign.new()
	_negative_sign.position = sign_position
	_negative_sign.sign_removed.connect(_on_sign_removed)
	add_child(_negative_sign)


func _build_trash_bin() -> void:
	_trash_bin = TrashBin.new()
	_trash_bin.position = trash_bin_position
	_trash_bin.is_functional = true
	add_child(_trash_bin)


func _connect_timer() -> void:
	LevelTimer.tick.connect(_on_timer_tick)


func _on_timer_tick(display_time: float) -> void:
	# display_time is the actual countdown (10 → 9 → 8... → 0)
	# We need to derive elapsed time from it
	_elapsed_time = time_limit - display_time
	_update_time_label()
	_emit_progress()


func _update_time_label() -> void:
	if _is_negative_mode:
		# Show negative values increasing: 0 → -1 → -2...
		var negative_display: float = -_elapsed_time
		_time_label.text = "%.2f" % negative_display
	else:
		# Show positive countdown: 10 → 9 → 8...
		var remaining: float = time_limit - _elapsed_time
		_time_label.text = "%.2f" % remaining


func _on_sign_removed() -> void:
	_is_negative_mode = false
	_update_time_label()


func _on_button_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_click()


func _handle_click() -> void:
	if _is_completed or _is_failed:
		return

	if LevelTimer.has_timed_out():
		return

	# Win condition: click when elapsed_time reaches time_limit (countdown hits 0)
	var remaining: float = time_limit - _elapsed_time
	if remaining <= 0.01:  # Allow small tolerance
		_time_label.text = "0.00"
		_complete()
	else:
		var display_value: float = _elapsed_time if _is_negative_mode else remaining
		var prefix: String = "-" if _is_negative_mode else ""
		_fail("Clicked at %s%.2f, need 0!" % [prefix, abs(display_value)])


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func get_progress_ratio() -> float:
	if _is_completed:
		return 1.0
	if not _is_negative_mode:
		return 0.5
	return 0.0


func get_progress_text() -> String:
	if _is_completed:
		return "Complete!"
	if not _is_negative_mode:
		return "Sign removed - click at 0.00!"
	return "Remove the negative sign or wait for -10.00"