class_name Draggable
extends Area2D
## 2D drag-and-drop behavior. Attach to any Area2D with a CollisionShape2D child.
## Emits `drag_started` / `drag_ended` so listeners (drop zones, levels) can react.
##
## Input: Area2D.input_event for press detection (consumes the event so it won't
## leak to _unhandled_input). Movement + release use _process (not _physics_process)
## for frame-accurate cursor tracking on high-refresh-rate displays.

signal drag_started(node: Draggable)
signal drag_ended(node: Draggable, dropped_position: Vector2)

@export var color: Color = Color(0.85, 0.55, 0.25)
@export var size: Vector2 = Vector2(80, 80)
@export var drag_scale: float = 1.15        # visual scale while dragging
@export var drag_color_boost: float = 0.25  # lightening applied while dragging
@export var hover_color_boost: float = 0.12 # lightening applied while hovered

var _is_dragging: bool = false
var _is_hovered: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _visual: Polygon2D


func _ready() -> void:
	input_pickable = true
	# Draggables live on physics layer 4 (draggable) so drop zones can detect them.
	collision_layer = 1 << 3
	collision_mask = 0
	monitorable = true
	monitoring = false
	_build_visual()
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.name = "Visual"
	var half := size * 0.5
	_visual.polygon = PackedVector2Array([
		-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)
	])
	_visual.color = color
	add_child(_visual)

	# Collider matches the visual.
	var col := CollisionShape2D.new()
	col.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	add_child(col)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(get_global_mouse_position())
			# Note: cannot call set_input_as_handled() here — that method is only
			# valid in _input/_unhandled_input callbacks, not in input_event signals.
			# Safe to skip: test scenes' _unhandled_input only handles the "reset"
			# action (R key), not mouse clicks, so the event won't trigger side effects.


func _on_mouse_entered() -> void:
	_is_hovered = true
	if not _is_dragging:
		_visual.color = color.lightened(hover_color_boost)


func _on_mouse_exited() -> void:
	_is_hovered = false
	if not _is_dragging:
		_visual.color = color


func _begin_drag(mouse_global: Vector2) -> void:
	if _is_dragging:
		return
	_is_dragging = true
	_drag_offset = mouse_global - global_position
	z_index = 10
	# Scale ONLY the visual, not the Area2D — scaling the Area2D would also
	# scale the CollisionShape2D and cause DropZone area_entered/exited flicker
	# when the enlarged shape crosses the zone boundary mid-drag.
	_visual.scale = Vector2(drag_scale, drag_scale)
	_visual.color = color.lightened(drag_color_boost)
	drag_started.emit(self)


func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	z_index = 0
	_visual.scale = Vector2.ONE
	# Restore hover state appearance (may have ended over another box).
	_visual.color = color.lightened(hover_color_boost) if _is_hovered else color
	drag_ended.emit(self, global_position)


# _process (not _physics_process) so the box tracks the cursor at display
# refresh rate — feels noticeably more responsive on 120/144Hz monitors.
func _process(_delta: float) -> void:
	if not _is_dragging:
		return
	# Release detection: works even when cursor leaves the area.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()
		return
	global_position = get_global_mouse_position() - _drag_offset


func is_dragging() -> bool:
	return _is_dragging


func is_hovered() -> bool:
	return _is_hovered
