class_name DragAllToZoneObjective
extends LevelObjective
## Win condition: drag N Draggable boxes into the drop zone.
## Builds the drop zone + the draggables itself, so the level scene only needs
## to position this node and configure counts/colors.

@export var zone_position: Vector2 = Vector2(380, 0)
@export var zone_size: Vector2 = Vector2(420, 420)
@export var zone_color: Color = Color(0.20, 0.55, 0.30, 0.45)
@export var required_count: int = 4
@export var draggable_size: Vector2 = Vector2(80, 80)
@export var draggable_colors: Array = [
	Color(0.85, 0.55, 0.25),
	Color(0.55, 0.65, 0.85),
	Color(0.85, 0.45, 0.55),
	Color(0.65, 0.85, 0.45),
]
@export var spawn_anchor: Vector2 = Vector2(-480, -120)
@export var spawn_step: Vector2 = Vector2(120, 140)

var _drop_zone: Area2D
var _zone_label: Label
var _in_zone_count: int = 0


func _ready() -> void:
	_build_drop_zone()
	_build_draggables()
	_emit_progress()


func _build_drop_zone() -> void:
	_drop_zone = Area2D.new()
	_drop_zone.name = "DropZone"
	_drop_zone.position = zone_position
	_drop_zone.collision_layer = 1 << 4  # drop_zone layer
	_drop_zone.collision_mask = 1 << 3   # detect draggable layer
	_drop_zone.monitoring = true
	_drop_zone.monitorable = false

	var rect := ColorRect.new()
	rect.size = zone_size
	rect.color = zone_color
	rect.position = -zone_size * 0.5
	_drop_zone.add_child(rect)

	_zone_label = Label.new()
	_zone_label.text = "DROP ZONE\n(0 / %d)" % required_count
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_zone_label.size = zone_size
	_zone_label.position = -zone_size * 0.5
	_zone_label.add_theme_font_size_override("font_size", 24)
	_drop_zone.add_child(_zone_label)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = zone_size
	col.shape = shape
	_drop_zone.add_child(col)

	_drop_zone.area_entered.connect(_on_area_entered)
	_drop_zone.area_exited.connect(_on_area_exited)
	add_child(_drop_zone)


func _build_draggables() -> void:
	for i in range(required_count):
		var d := Draggable.new()
		var col_idx: int = i % draggable_colors.size()
		var col: Color = draggable_colors[col_idx]
		var grid_pos := Vector2(i % 2, i / 2)
		d.position = spawn_anchor + grid_pos * spawn_step
		d.color = col
		d.size = draggable_size
		add_child(d)


func _on_area_entered(area: Area2D) -> void:
	if area is Draggable:
		_in_zone_count += 1
		_emit_progress()
		_check_complete()


func _on_area_exited(area: Area2D) -> void:
	if area is Draggable:
		_in_zone_count = max(_in_zone_count - 1, 0)
		_emit_progress()


func _check_complete() -> void:
	if _in_zone_count >= required_count:
		_complete()


func get_progress_ratio() -> float:
	if required_count <= 0:
		return 1.0 if _is_completed else 0.0
	return clampf(float(_in_zone_count) / float(required_count), 0.0, 1.0)


func get_progress_text() -> String:
	return "%d / %d" % [_in_zone_count, required_count]


func _emit_progress() -> void:
	if _zone_label:
		_zone_label.text = "DROP ZONE\n(%d / %d)" % [_in_zone_count, required_count]
	super._emit_progress()
