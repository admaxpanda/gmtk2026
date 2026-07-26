class_name NegativeSign
extends Area2D
## Draggable negative sign that flips the timer's counting direction.
## When present: timer counts UP as a plain number (1 → 2 → ... → 10) — a deception.
## When removed: timer counts DOWN (10 → 9 → ... → 0) — the true countdown.
##
## Visual: Blue "−" glyph (Label), not a sign actually applied to the number.
## Behavior: Draggable, snaps back if dropped outside trash bin.

signal dropped_in_trash
signal sign_removed  # Emitted when trashed, for timer to revert display

@export var sign_size: Vector2 = Vector2(60, 60)
@export var sign_color: Color = Color(0.25, 0.45, 0.75)
@export var line_width: float = 8.0

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _visual: Label
var _is_trashed: bool = false


func _ready() -> void:
	input_pickable = true
	collision_layer = 1 << 3  # draggable layer
	# Monitor the drop-zone layer (4) so get_overlapping_areas() reports the
	# TrashBin on drop. Without this the sign is never detected and always snaps back.
	collision_mask = 1 << 4
	monitoring = true
	monitorable = true

	_build_visual()
	input_event.connect(_on_input_event)
	_original_position = position


func _build_visual() -> void:
	# Render an actual minus-sign glyph so the draggable clearly reads as "−".
	_visual = Label.new()
	_visual.name = "Visual"
	_visual.text = "\u2212"  # true minus sign
	_visual.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_visual.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_visual.add_theme_font_size_override("font_size", 72)
	_visual.add_theme_color_override("font_color", sign_color)
	# Controls would otherwise swallow the mouse and break Area2D picking.
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.custom_minimum_size = sign_size
	_visual.size = sign_size
	_visual.position = -sign_size * 0.5
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
	_visual.add_theme_color_override("font_color", sign_color.lightened(0.2))
	_visual.scale = Vector2(1.15, 1.15)


func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	z_index = 0
	_visual.add_theme_color_override("font_color", sign_color)
	_visual.scale = Vector2(1.0, 1.0)

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