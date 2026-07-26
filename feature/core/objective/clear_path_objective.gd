class_name ClearPathObjective
extends LevelObjective
## Level 3 objective: Clear Path.
## - A blue paper block covers the button
## - Player must drag the block to trash bin to reveal the button (gate)
## - Then click the button when the countdown hits `target_remaining` (within
##   `tolerance`) to win. Time is the win condition (ref. Level 1: Stop the Clock).

@export var button_position: Vector2 = Vector2(960, 540)
@export var button_radius: float = 110.0
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var block_size: Vector2 = Vector2(260, 260)
@export var block_color: Color = Color(0.25, 0.45, 0.75)
@export var trash_bin_position: Vector2 = Vector2(1720, 930)
@export var timer_display_position: Vector2 = Vector2(960, 200)  # Center-top for timer display
@export var target_remaining: float = 0.0  # Win by clicking when remaining time hits this (ref. Level 1)
@export var tolerance: float = 0.25  # +/- window around target_remaining

var _button: Area2D
var _timer_label: Label
var _paper_block: PaperBlock
var _trash_bin: TrashBin
var _is_block_removed: bool = false


func _ready() -> void:
	_build_trash_bin()
	_build_timer_display()
	_build_button()
	_build_paper_block()

	# F6 dev support
	if LevelManager.get_current_level_id() == "":
		var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
		LevelManager.begin_dev_test(level_id)

	_emit_progress()


func _build_timer_display() -> void:
	# Timer label at center-top
	_timer_label = Label.new()
	_timer_label.text = "0.00"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 48)
	_timer_label.add_theme_color_override("font_color", Color.WHITE)
	_timer_label.position = timer_display_position - Vector2(50, 24)
	_timer_label.custom_minimum_size = Vector2(100, 48)
	add_child(_timer_label)

	# Connect to timer updates
	LevelTimer.tick.connect(_on_timer_tick)


func _on_timer_tick(display_time: float) -> void:
	_timer_label.text = "%.2f" % display_time
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

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = button_radius
	col.shape = shape
	_button.add_child(col)

	_button.input_event.connect(_on_button_input)
	add_child(_button)


func _build_paper_block() -> void:
	_paper_block = PaperBlock.new()
	_paper_block.position = button_position  # Cover the button
	_paper_block.block_size = block_size
	_paper_block.block_color = block_color
	_paper_block.dropped_in_trash.connect(_on_block_trashed)
	add_child(_paper_block)


func _build_trash_bin() -> void:
	_trash_bin = TrashBin.new()
	_trash_bin.position = trash_bin_position
	_trash_bin.is_functional = true
	add_child(_trash_bin)


func _on_button_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_click()


func _handle_click() -> void:
	if _is_completed or _is_failed:
		return
	# Late clicks after the countdown expired are handled by BaseLevel's
	# timed_out (level fails), so block them explicitly (matches Level 1).
	if LevelTimer.has_timed_out():
		return
	# The button is covered by the block until the path is cleared.
	# Clicking before that is meaningless — ignore (puzzle gate, not a fail).
	if not _is_block_removed:
		return
	# Path is clear: the win condition is purely time-based, like Level 1
	# (Stop the Clock). Click within `tolerance` of `target_remaining` to win;
	# clicking at the wrong time fails ("Too early!").
	var remaining: float = LevelTimer.get_remaining()
	if abs(remaining - target_remaining) <= tolerance:
		_timer_label.text = "0.00"
		_complete()
	else:
		_fail("Too early!")


func _on_block_trashed() -> void:
	_is_block_removed = true
	_emit_progress()


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func get_progress_ratio() -> float:
	return 1.0 if _is_completed else 0.0


func get_progress_text() -> String:
	if _is_completed:
		return "Complete!"
	if not _is_block_removed:
		return "Drag the blue block to the trash"
	if LevelTimer.is_countdown():
		return "%.2fs left — click at 0.00" % LevelTimer.get_remaining()
	return ""