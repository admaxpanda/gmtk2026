extends Node2D
## Test: Draggable component.
## Verifies: click-to-drag, mouse follow, release-to-drop, re-draggable, drag signals,
##           hover/drag visual feedback.
## Run with F6 in the editor.

const BOX_COLORS: Array = [
	Color(0.85, 0.55, 0.25),
	Color(0.55, 0.65, 0.85),
	Color(0.85, 0.45, 0.55),
	Color(0.65, 0.85, 0.45),
]
const BOX_SIZE := Vector2(100, 100)
const BOX_SPACING := 200.0

var _drag_count: int = 0
var _status_label: Label
var _count_label: Label
var _position_label: Label
var _hover_label: Label
var _boxes: Array = []


func _ready() -> void:
	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))
	add_child(SceneHelpers.make_label("TEST: Draggable", Vector2(40, 20), 28))
	add_child(SceneHelpers.make_label(
		"Click and drag the boxes (they grow + brighten while dragged, brighten on hover). Release to drop. R to reset.",
		Vector2(40, 60), 16, Color(0.7, 0.7, 0.75)))

	_hover_label = SceneHelpers.make_label("Hover: none", Vector2(40, 100), 18, Color(0.85, 0.75, 0.45))
	_status_label = SceneHelpers.make_label("Dragging: none", Vector2(40, 130), 18, Color(0.9, 0.85, 0.5))
	_count_label = SceneHelpers.make_label("Total drag starts: 0", Vector2(40, 160), 18)
	_position_label = SceneHelpers.make_label("", Vector2(40, 200), 14, Color(0.65, 0.65, 0.7))
	add_child(_hover_label)
	add_child(_status_label)
	add_child(_count_label)
	add_child(_position_label)

	_spawn_boxes()

	var back_btn := SceneHelpers.make_button("← Back to Test Menu", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)

	var reset_btn := SceneHelpers.make_button("Reset (R)", Vector2(240, 660))
	reset_btn.pressed.connect(_on_reset)
	add_child(reset_btn)


func _spawn_boxes() -> void:
	for i in range(BOX_COLORS.size()):
		var d := Draggable.new()
		d.position = Vector2(220 + i * BOX_SPACING, 400)
		d.color = BOX_COLORS[i]
		d.size = BOX_SIZE
		add_child(d)
		d.drag_started.connect(_on_drag_started)
		d.drag_ended.connect(_on_drag_ended)
		_boxes.append(d)


func _on_drag_started(node: Draggable) -> void:
	_drag_count += 1
	_count_label.text = "Total drag starts: %d" % _drag_count
	_status_label.text = "Dragging: box #%d" % (_boxes.find(node) + 1)


func _on_drag_ended(node: Draggable, _pos: Vector2) -> void:
	_status_label.text = "Dragging: none (dropped box #%d)" % (_boxes.find(node) + 1)


func _process(_delta: float) -> void:
	# Report hover state (first hovered box wins if overlapping).
	var hovered_idx := -1
	for i in range(_boxes.size()):
		if is_instance_valid(_boxes[i]) and _boxes[i].is_hovered():
			hovered_idx = i
			break
	_hover_label.text = "Hover: %s" % ("box #%d" % (hovered_idx + 1) if hovered_idx >= 0 else "none")

	# Live position readout for diagnostics.
	var parts: Array = []
	for i in range(_boxes.size()):
		if is_instance_valid(_boxes[i]):
			var tag := "*" if _boxes[i].is_dragging() else " "
			parts.append("%sbox%d: (%.0f, %.0f)" % [tag, i + 1, _boxes[i].position.x, _boxes[i].position.y])
	_position_label.text = "\n".join(parts)


func _on_reset() -> void:
	for i in range(_boxes.size()):
		if is_instance_valid(_boxes[i]):
			_boxes[i].position = Vector2(220 + i * BOX_SPACING, 400)
	_drag_count = 0
	_count_label.text = "Total drag starts: 0"
	_status_label.text = "Dragging: none"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset"):
		_on_reset()
