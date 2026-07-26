class_name DigitDropObjective
extends LevelObjective
## Level 2 objective: Digit Drop.
## - Start with 11110 seconds (virtual timer shows "1111", main shows "0")
## - Player can drag virtual timer to trash bin to truncate time to units digit
## - Win condition: first drop the virtual timer into the trash to truncate time to its units digit, then click when the remaining total reaches 0
## - Fail condition: click before dropping the virtual timer, click too early (remaining > 0), or timer reaches 0 without click

@export var button_position: Vector2 = Vector2(960, 540)
@export var button_radius: float = 110.0
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var timer_display_position: Vector2 = Vector2(960, 200)  # Center-top for timer display
@export var trash_bin_position: Vector2 = Vector2(1720, 930)  # Bottom-right corner

var _button: Area2D
var _units_label: Label
var _virtual_timer: VirtualTimer
var _trash_bin: TrashBin
var _is_truncated: bool = false


func _ready() -> void:
	_build_virtual_timer()
	_build_trash_bin()
	_build_button()
	_connect_timer()

	# F6 dev support
	if LevelManager.get_current_level_id() == "":
		var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
		LevelManager.begin_dev_test(level_id)

	_emit_progress()


func _build_virtual_timer() -> void:
	# Shared row geometry so the virtual (high-digit) timer and the main (units)
	# timer form one aligned number row with a common baseline.
	var row_width: float = 170.0
	var row_height: float = 100.0
	var center_x: float = timer_display_position.x
	var center_y: float = timer_display_position.y

	# The main counter renders its digits at font size 64. To make the virtual
	# counter's digits the SAME size, give it the same font size. The virtual
	# counter is wrapped in a Panel with a 12px content border, so we also
	# Right-align its digits against the inner right edge: that way the number
	# hugs the shared boundary with the main counter and the border does not
	# crowd the glyphs or make them look smaller than the main counter's.
	var main_font_size: int = 64
	var inner_gap: float = 12.0  # spacing between the virtual border and the main digits

	# Virtual timer (high digits) on the left side of the display.
	_virtual_timer = VirtualTimer.new()
	_virtual_timer.panel_size = Vector2(row_width, row_height)
	_virtual_timer.font_size = main_font_size
	_virtual_timer.text_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_virtual_timer.position = Vector2(center_x - 100, center_y)
	_virtual_timer.dropped_in_trash.connect(_on_virtual_timer_trashed)
	add_child(_virtual_timer)

	# Units digit label on the right side. Same font size as the virtual counter
	# so the two halves read as one continuous number. Left-align it and sit it
	# immediately to the right of the virtual timer's border (inner_gap) so the
	# digit spacing between the last high digit and the first units digit matches
	# the natural spacing inside each half, making the display read as "11110.00".
	var virtual_right_edge: float = _virtual_timer.position.x + row_width * 0.5
	_units_label = Label.new()
	_units_label.text = "0"
	_units_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_units_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_units_label.add_theme_font_size_override("font_size", main_font_size)
	_units_label.add_theme_color_override("font_color", Color.WHITE)
	_units_label.custom_minimum_size = Vector2(row_width, row_height)
	_units_label.size = Vector2(row_width, row_height)
	_units_label.position = Vector2(virtual_right_edge + inner_gap, center_y - row_height * 0.5)
	add_child(_units_label)


func _build_trash_bin() -> void:
	_trash_bin = TrashBin.new()
	_trash_bin.position = trash_bin_position
	_trash_bin.is_functional = true
	add_child(_trash_bin)


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

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = button_radius
	col.shape = shape
	_button.add_child(col)

	_button.input_event.connect(_on_button_input)
	add_child(_button)


func _connect_timer() -> void:
	LevelTimer.tick.connect(_on_timer_tick)
	LevelTimer.truncated_to_units.connect(_on_timer_truncated)


func _on_timer_tick(_display_time: float) -> void:
	_update_display()
	_emit_progress()


func _on_timer_truncated(_units: int) -> void:
	_is_truncated = true
	_update_display()


func _update_display() -> void:
	# Main timer shows the units "slot" of the countdown (time mod 10) with
	# 2-decimal precision. Combined with the VirtualTimer's high digits this equals
	# the actual time: virtual_high_digits * 10 + this_remainder.
	var display_time: float = LevelTimer.get_display_time()
	var main_value: float = fmod(display_time, 10.0)
	_units_label.text = "%.2f" % main_value


func _on_button_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_click()


func _handle_click() -> void:
	if _is_completed or _is_failed:
		return

	# Check if timer has timed out
	if LevelTimer.has_timed_out():
		return

	# Win condition is evaluated on the SUM of the virtual (high digits) and the
	# main (units) counters — i.e. the actual remaining time. You must first drop
	# the virtual timer into the trash to truncate the time down to its units
	# digit; only then does clicking at 0 (the truncated total reaching 0) win.
	if not _is_truncated:
		_fail("Drop the virtual timer into the trash first!")
		return

	var total_time: float = LevelTimer.get_high_digits() * 10.0 + fmod(LevelTimer.get_display_time(), 10.0)
	var units: int = int(total_time) % 10
	if units == 0:
		_units_label.text = "0.00"
		_complete()
	else:
		var main_value: float = fmod(LevelTimer.get_display_time(), 10.0)
		_fail("Clicked at %.2f, need 0.00! (total %.2f)" % [main_value, total_time])


func _on_virtual_timer_trashed() -> void:
	_is_truncated = true
	_update_display()


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func get_progress_ratio() -> float:
	if _is_completed:
		return 1.0
	if _is_truncated:
		return 0.5
	return 0.0


func get_progress_text() -> String:
	if _is_completed:
		return "Complete!"
	if _is_truncated:
		return "Timer truncated - click at 0!"
	return "Drag timer to trash or wait for 0"