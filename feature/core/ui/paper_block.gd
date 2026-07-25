class_name PaperBlock
extends Area2D
## Draggable paper block that covers the button.
## When dropped in trash bin, disappears and reveals the button.
##
## Visual: Blue paper-like block with rounded corners.
## Behavior: Draggable, snaps back if dropped outside trash bin.

signal dropped_in_trash

@export var block_size: Vector2 = Vector2(260, 260)
@export var block_color: Color = Color(0.25, 0.45, 0.75)
@export var border_color: Color = Color(0.18, 0.35, 0.60)

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _visual: Polygon2D
var _is_trashed: bool = false


func _ready() -> void:
	input_pickable = true
	collision_layer = 1 << 3  # draggable layer
	collision_mask = 0
	monitoring = false
	monitorable = true

	_build_visual()
	input_event.connect(_on_input_event)
	_original_position = position


func _build_visual() -> void:
	# Rounded rectangle paper block
	_visual = Polygon2D.new()
	_visual.name = "Visual"
	_visual.polygon = _make_rounded_rect(block_size, 16)
	_visual.color = block_color
	add_child(_visual)

	# Collision shape
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = block_size
	col.shape = shape
	add_child(col)


func _make_rounded_rect(size: Vector2, corner_radius: float) -> PackedVector2Array:
	var half := size * 0.5
	var r := corner_radius
	var pts := PackedVector2Array()
	var segments_per_corner := 8

	# Top-left corner
	for i in segments_per_corner:
		var a := PI + PI * 0.5 * float(i) / float(segments_per_corner)
		pts.append(Vector2(-half.x + r, -half.y + r) + Vector2(cos(a), sin(a)) * r)

	# Top-right corner
	for i in segments_per_corner:
		var a := PI * 1.5 + PI * 0.5 * float(i) / float(segments_per_corner)
		pts.append(Vector2(half.x - r, -half.y + r) + Vector2(cos(a), sin(a)) * r)

	# Bottom-right corner
	for i in segments_per_corner:
		var a := PI * 0.0 + PI * 0.5 * float(i) / float(segments_per_corner)
		pts.append(Vector2(half.x - r, half.y - r) + Vector2(cos(a), sin(a)) * r)

	# Bottom-left corner
	for i in segments_per_corner:
		var a := PI * 0.5 + PI * 0.5 * float(i) / float(segments_per_corner)
		pts.append(Vector2(-half.x + r, half.y - r) + Vector2(cos(a), sin(a)) * r)

	return pts


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
	_visual.color = block_color.lightened(0.15)
	_visual.scale = Vector2(1.05, 1.05)


func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	z_index = 0
	_visual.color = block_color
	_visual.scale = Vector2.ONE

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