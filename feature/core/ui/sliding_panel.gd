class_name SlidingPanel
extends AnimatableBody2D
## Panel that slides UP when the linked PulleyPlatform sinks.
## Uses pulley physics: when platform goes down by N, panel goes up by N.
##
## Behavior:
## - Listens to platform.moved signal
## - Moves opposite direction (panel rises when platform sinks)
## - Has solid collision to block the player from reaching the button
## - When panel rises enough, button becomes accessible

@export var panel_size: Vector2 = Vector2(140, 280)
@export var panel_color: Color = Color(0.30, 0.30, 0.35)
@export var max_rise: float = 200.0  # Maximum the panel can rise

var _original_position: Vector2 = Vector2.ZERO
var _current_rise: float = 0.0  # 0 = original, max_rise = fully raised
var _visual: ColorRect


func _ready() -> void:
	_original_position = position
	collision_layer = 1 << 1  # solid (blocks player)
	collision_mask = 1 << 0   # collide with / detect the player

	_build_visual()


func _build_visual() -> void:
	_visual = ColorRect.new()
	_visual.name = "Visual"
	_visual.size = panel_size
	_visual.color = panel_color
	_visual.position = -panel_size * 0.5
	add_child(_visual)

	var col := CollisionShape2D.new()
	col.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = panel_size
	col.shape = shape
	add_child(col)

	# Explicit collision cap at the very top of the panel so its top is a clean,
	# reliable standable surface (the player can land on / stand on the panel top
	# rather than clipping the thin top edge of the full-body shape).
	var top_cap := CollisionShape2D.new()
	top_cap.name = "TopCap"
	var top_shape := RectangleShape2D.new()
	top_shape.size = Vector2(panel_size.x, 16.0)
	top_cap.shape = top_shape
	top_cap.position = Vector2(0.0, -panel_size.y * 0.5 - 8.0)
	add_child(top_cap)


## Called when the linked platform moves. delta_y > 0 means platform sank,
## so panel rises (moves up = negative y).
func on_platform_moved(delta_y: float) -> void:
	# Platform moves down by delta_y, panel moves up by delta_y
	var new_rise: float = clamp(_current_rise + delta_y, 0.0, max_rise)
	_current_rise = new_rise
	position.y = _original_position.y - _current_rise


func get_rise() -> float:
	return _current_rise


func is_fully_raised() -> bool:
	return _current_rise >= max_rise - 1.0


func reset_panel() -> void:
	_current_rise = 0.0
	position.y = _original_position.y