extends Control
## Test menu: launches individual test scenes via change_scene_to_file.
## Run this scene (F6) to pick a test, or open any test_*.tscn directly.

const TESTS: Array = [
	{"name": "Draggable", "desc": "2D drag-and-drop component", "path": "res://tests/test_draggable.tscn"},
	{"name": "Platformer", "desc": "PlayerPlatformer + coyote/buffer state", "path": "res://tests/test_platformer.tscn"},
	{"name": "Top-Down", "desc": "PlayerTopDown 8-directional movement", "path": "res://tests/test_topdown.tscn"},
	{"name": "Timer (Count Up/Down)", "desc": "LevelTimer dual-mode + timed_out", "path": "res://tests/test_timer.tscn"},
	{"name": "Save Manager", "desc": "SaveManager direction-aware best times", "path": "res://tests/test_save.tscn"},
	{"name": "Objective System", "desc": "ReachGoal + DragAllToZone objectives", "path": "res://tests/test_objective.tscn"},
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.offset_left = 120
	root.offset_right = -120
	root.offset_top = 60
	root.offset_bottom = -60
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "TEST MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Each test scene is self-contained — press F6 to run, R to reset, Esc/back to return."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	subtitle.add_theme_font_size_override("font_size", 14)
	root.add_child(subtitle)

	root.add_child(HSeparator.new())

	for entry in TESTS:
		root.add_child(_make_test_row(entry))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var back_btn := Button.new()
	back_btn.text = "← Back to Game Main Menu"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	root.add_child(back_btn)


func _make_test_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)

	var name_lbl := Label.new()
	name_lbl.text = entry["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = entry["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	info.add_child(desc_lbl)

	row.add_child(info)

	var run_btn := Button.new()
	run_btn.text = "Run"
	run_btn.custom_minimum_size = Vector2(120, 50)
	run_btn.pressed.connect(func(): get_tree().change_scene_to_file(entry["path"]))
	row.add_child(run_btn)

	return row
