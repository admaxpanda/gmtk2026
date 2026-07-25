class_name VirtualTimer
extends Area2D
## Draggable timer display showing high digits (tens, hundreds, thousands, etc.).
## Used in Level 2 (Digit Drop) to allow players to truncate time to units digit.
##
## Behavior:
## - Displays high digits from LevelTimer (e.g., "1111" for time 11110)
## - Can be dragged around the screen
## - If dropped outside trash bin, snaps back to original position
## - If dropped in trash bin (TrashBin), triggers LevelTimer.truncate_to_units()

signal dropped_in_trash
signal snapped_back

@export var panel_size: Vector2 = Vector2(160, 60)
@export var font_size: int = 28
@export var bg_color: Color = Color(0.12, 0.14, 0.18)
@export var text_color: Color = Color(0.95, 0.95, 0.95)

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _label: Label
var _panel: PanelContainer
var _is_trashed: bool = false


func _ready() -> void:
	input_pickable = true
	collision_layer = 1 << 3  # clickable/draggable layer
	collision_mask = 0
	monitoring = false
	monitorable = true

	_build_ui()
	_connect_timer()
	input_event.connect(_on_input_event)
	_original_position = position


func _build_ui() -> void:
	# Panel container for background
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Label for displaying high digits
	_label = Label.new()
	_label.text = "0"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", text_color)
	_panel.add_child(_label)

	# Collision shape for drag detection
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = panel_size
	col.shape = shape
	add_child(col)


func _connect_timer() -> void:
	LevelTimer.tick.connect(_on_timer_tick)
	# Initial display
	_update_display()


func _update_display() -> void:
	if _is_trashed:
		return
	var high_digits: int = LevelTimer.get_high_digits()
	_label.text = "%d" % high_digits


func _on_timer_tick(_display_time: float) -> void:
	_update_display()


# ---------- Drag Logic ----------

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _is_trashed:
			_begin_drag(get_global_mouse_position())


func _begin_drag(mouse_global: Vector2) -> void:
	if _is_dragging or _is_trashed:
		return
	_is_dragging = true
	_drag_offset = mouse_global - global_position
	z_index = 10
	# Visual feedback - slightly larger and brighter
	_panel.scale = Vector2(1.05, 1.05)
	_label.add_theme_color_override("font_color", text_color.lightened(0.2))


func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	z_index = 0
	_panel.scale = Vector2.ONE
	_label.add_theme_color_override("font_color", text_color)

	# Check if dropped in trash bin by checking collision with TrashBin
	var dropped_in_trash: bool = false
	var areas: Array[Area2D] = get_overlapping_areas()
	for area in areas:
		if area is TrashBin:
			dropped_in_trash = true
			break

	if dropped_in_trash:
		_handle_drop_in_trash()
	else:
		_snap_back()


func _handle_drop_in_trash() -> void:
	_is_trashed = true
	visible = false
	LevelTimer.truncate_to_units()
	dropped_in_trash.emit()


func _snap_back() -> void:
	# Animate back to original position
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", _original_position, 0.3)
	snapped_back.emit()


func _process(_delta: float) -> void:
	if not _is_dragging:
		return
	# Release detection
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()
		return
	# Follow cursor
	global_position = get_global_mouse_position() - _drag_offset


func is_dragging() -> bool:
	return _is_dragging


func is_trashed() -> bool:
	return _is_trashed