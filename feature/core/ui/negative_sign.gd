class_name NegativeSign
extends Area2D
## Draggable negative sign that inverts the timer display.
## When present: timer shows negative values (e.g., -10, -9, -8...)
## When removed: timer shows positive values (e.g., 10, 9, 8...)
##
## Visual: Blue negative sign symbol.
## Behavior: Draggable, snaps back if dropped outside trash bin.

signal dropped_in_trash
signal sign_removed  # Emitted when trashed, for timer to revert display

@export var sign_size: Vector2 = Vector2(60, 60)
@export var sign_color: Color = Color(0.25, 0.45, 0.75)
@export var line_width: float = 8.0

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _visual: Line2D
var _is_trashed: bool = false


func _ready() -> void:
	input_pickable = true
	collision_layer = 1 << 3  # draggable layer
	collision_mask = 0
	monitoring = false
	monitorable = true

	_build_visual()
	_original_position = position


func _build_visual() -> void:
	# Draw a horizontal line (minus sign)
	_visual = Line2D.new()
	_visual.name = "Visual"
	_visual.width = line_width
	_visual.default_color = sign_color
	_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	_visual.add_point(Vector2(-sign_size.x * 0.5, 0))
	_visual.add_point(Vector2(sign_size.x * 0.5, 0))
	add_child(_visual)

	# Collision shape
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = sign_size
	col.shape = shape
	add_child(col)


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
	# Visual feedback
	_visual.default_color = sign_color.lightened(0.2)
	_visual.width = line_width * 1.2


func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	z_index = 0
	_visual.default_color = sign_color
	_visual.width = line_width

	# Check if dropped in trash bin
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
	sign_removed.emit()
	dropped_in_trash.emit()


func _snap_back() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", _original_position, 0.3)


func _process(_delta: float) -> void:
	if not _is_dragging:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()
		return
	global_position = get_global_mouse_position() - _drag_offset


func is_dragging() -> bool:
	return _is_dragging


func is_trashed() -> bool:
	return _is_trashed