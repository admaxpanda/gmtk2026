extends Control
## Main menu / level select. Reads LevelManager registry + SaveManager state.
## Shows lock/unlock status, best time, and overall progress.

var _level_rows: Array = []  # for refresh after reset


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	_level_rows.clear()
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.11, 0.16)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.offset_left = 80
	root.offset_right = -80
	root.offset_top = 40
	root.offset_bottom = -40
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "GMTK COUNTDOWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	root.add_child(title)

	var progress: Dictionary = LevelManager.get_progress()
	var progress_lbl := Label.new()
	progress_lbl.text = "Progress: %d / %d levels completed" % [progress["completed"], progress["total"]]
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 16)
	progress_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	root.add_child(progress_lbl)

	root.add_child(HSeparator.new())

	for level_id in LevelManager.get_level_ids():
		var row := _make_level_row(level_id)
		_level_rows.append(row)
		root.add_child(row)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	root.add_child(spacer)

	var reset_btn := Button.new()
	reset_btn.text = "Reset All Save Data"
	reset_btn.pressed.connect(_on_reset_all)
	root.add_child(reset_btn)


func _make_level_row(level_id: String) -> Control:
	var meta: Dictionary = LevelManager.get_level_metadata(level_id)
	var unlocked: bool = LevelManager.is_level_unlocked(level_id)
	var completed: bool = SaveManager.is_level_completed(level_id)
	var best: float = SaveManager.get_best_time(level_id)
	var is_countdown: bool = meta.get("timer_mode", "count_up") == "count_down"
	var time_limit: float = float(meta.get("time_limit", 0.0))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)

	var title := Label.new()
	title.text = meta.get("title", level_id)
	title.add_theme_font_size_override("font_size", 20)
	if not unlocked:
		title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	info.add_child(title)

	var subtitle := Label.new()
	var sub_text: String = meta.get("subtitle", "")
	if is_countdown and time_limit > 0.0:
		sub_text += "  (%ds limit)" % int(time_limit)
	subtitle.text = sub_text
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	info.add_child(subtitle)

	var status := Label.new()
	if not unlocked:
		status.text = "Locked — complete previous level to unlock"
		status.add_theme_color_override("font_color", Color(0.7, 0.5, 0.4))
	elif completed:
		var best_str: String = _fmt(best) if is_finite(best) else "--:--.---"
		if is_countdown:
			status.text = "Best: %s left  ✓" % best_str
		else:
			status.text = "Best: %s  ✓" % best_str
		status.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	else:
		if is_countdown:
			status.text = "Available — Countdown %ds" % int(time_limit)
		else:
			status.text = "Available — Count Up"
		status.add_theme_color_override("font_color", Color(0.8, 0.75, 0.45))
	info.add_child(status)

	row.add_child(info)

	var play_btn := Button.new()
	play_btn.custom_minimum_size = Vector2(120, 60)
	if unlocked:
		play_btn.text = "Play"
		play_btn.disabled = false
		play_btn.pressed.connect(func(): LevelManager.load_level(level_id))
	else:
		play_btn.text = "Locked"
		play_btn.disabled = true
	row.add_child(play_btn)

	return row


func _on_reset_all() -> void:
	SaveManager.reset_all()
	_build_ui()


func _fmt(seconds: float) -> String:
	var s: float = max(seconds, 0.0)
	var mins: int = int(s) / 60
	var secs: int = int(s) % 60
	var ms: int = int(fmod(s, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [mins, secs, ms]
