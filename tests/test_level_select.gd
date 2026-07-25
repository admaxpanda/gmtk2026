extends Control
## Test scene for LevelManager auto-discovery + LevelSelect.
## Displays scan results (count, per-level metadata) and provides buttons
## to jump to LevelSelect and to reset save data (for testing lock/unlock).

var _summary_label: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	title.text = "Level Discovery Test"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	_summary_label = Label.new()
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.add_theme_font_size_override("font_size", 16)
	_summary_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	root.add_child(_summary_label)

	root.add_child(HSeparator.new())

	var levels_box := VBoxContainer.new()
	levels_box.add_theme_constant_override("separation", 8)
	for level_id in LevelManager.get_level_ids():
		levels_box.add_child(_make_level_row(level_id))
	root.add_child(levels_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var open_btn := Button.new()
	open_btn.text = "Open LevelSelect"
	open_btn.custom_minimum_size = Vector2(0, 50)
	open_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	root.add_child(open_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset Save (test lock state)"
	reset_btn.custom_minimum_size = Vector2(0, 50)
	reset_btn.pressed.connect(func():
		SaveManager.reset_all()
		_refresh_summary())
	root.add_child(reset_btn)

	var back_btn := Button.new()
	back_btn.text = "Back to Test Menu"
	back_btn.custom_minimum_size = Vector2(0, 50)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	root.add_child(back_btn)

	_refresh_summary()


func _make_level_row(level_id: String) -> Control:
	var meta: Dictionary = LevelManager.get_level_metadata(level_id)
	var order: int = int(meta.get("order", 0))
	var title: String = meta.get("title", level_id)
	var timer_mode: String = meta.get("timer_mode", "count_up")
	var time_limit: float = float(meta.get("time_limit", 0.0))
	var path: String = meta.get("path", "")

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var main_lbl := Label.new()
	main_lbl.text = "[%d] %s — %s (%s, %ss)" % [order, level_id, title, timer_mode, time_limit]
	main_lbl.add_theme_font_size_override("font_size", 18)
	row.add_child(main_lbl)

	var path_lbl := Label.new()
	path_lbl.text = path
	path_lbl.add_theme_font_size_override("font_size", 13)
	path_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	row.add_child(path_lbl)

	return row


func _refresh_summary() -> void:
	var ids: Array = LevelManager.get_level_ids()
	var progress: Dictionary = LevelManager.get_progress()
	_summary_label.text = "Discovered: %d levels\nProgress: %d / %d" % [ids.size(), progress["completed"], progress["total"]]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://tests/test_menu.tscn")
