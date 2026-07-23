extends CanvasLayer
## Persistent HUD. Shows the per-level timer, objective progress, controls hint,
## and pause / complete menus. Listens to SignalBus / LevelTimer so it has zero
## direct coupling to level scenes.

var _timer_label: Label
var _best_label: Label
var _mode_label: Label
var _progress_label: Label
var _hint_label: Label
var _root_panel: PanelContainer
var _pause_panel: PanelContainer
var _pause_center: CenterContainer
var _complete_panel: PanelContainer
var _complete_center: CenterContainer
var _complete_time_label: Label
var _next_btn: Button
var _is_paused: bool = false
var _is_countdown: bool = false
const _WARN_COLOR: Color = Color(0.95, 0.35, 0.35)
const _OK_COLOR: Color = Color(0.95, 0.95, 0.95)


func _ready() -> void:
	layer = 50
	# Always process so the pause menu stays interactive when get_tree().paused=true.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_all()
	SignalBus.level_started.connect(_on_level_started)
	SignalBus.level_completed.connect(_on_level_completed)
	SignalBus.objective_progress.connect(_on_objective_progress)
	LevelTimer.tick.connect(_on_timer_tick)


func _build_ui() -> void:
	_root_panel = PanelContainer.new()
	_root_panel.name = "TopBar"
	_root_panel.custom_minimum_size = Vector2(360, 96)
	_root_panel.position = Vector2(20, 20)
	var root_vb := VBoxContainer.new()
	_root_panel.add_child(root_vb)

	_timer_label = Label.new()
	_timer_label.name = "Timer"
	_timer_label.text = "00:00.000"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 28)
	root_vb.add_child(_timer_label)

	_best_label = Label.new()
	_best_label.name = "Best"
	_best_label.text = "Best: --:--.---"
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override("font_size", 14)
	root_vb.add_child(_best_label)

	_mode_label = Label.new()
	_mode_label.name = "Mode"
	_mode_label.text = ""
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_size_override("font_size", 12)
	_mode_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	root_vb.add_child(_mode_label)

	_progress_label = Label.new()
	_progress_label.name = "Objective"
	_progress_label.text = ""
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 16)
	_progress_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	root_vb.add_child(_progress_label)

	add_child(_root_panel)

	# Bottom controls hint
	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.text = ""
	_hint_label.position = Vector2(20, 660)
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	add_child(_hint_label)

	_build_pause_panel()
	_build_complete_panel()


func _build_pause_panel() -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.name = "PausePanel"
	_pause_panel.custom_minimum_size = Vector2(360, 240)
	_pause_center = CenterContainer.new()
	_pause_center.add_child(_pause_panel)
	_fullscreen_center(_pause_center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_pause_panel.add_child(vb)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vb.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Resume (Esc)"
	resume_btn.pressed.connect(_toggle_pause)
	vb.add_child(resume_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Level (R)"
	restart_btn.pressed.connect(_on_restart)
	vb.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Back to Menu"
	menu_btn.pressed.connect(_on_back_to_menu)
	vb.add_child(menu_btn)

	# Hide the CENTER (not just the panel) — a visible full-screen CenterContainer
	# with mouse_filter=STOP eats every click before Area2D.input_event can fire.
	_pause_center.visible = false
	add_child(_pause_center)


func _build_complete_panel() -> void:
	_complete_panel = PanelContainer.new()
	_complete_panel.name = "CompletePanel"
	_complete_panel.custom_minimum_size = Vector2(420, 280)
	_complete_center = CenterContainer.new()
	_complete_center.add_child(_complete_panel)
	_fullscreen_center(_complete_center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_complete_panel.add_child(vb)

	var title := Label.new()
	title.text = "LEVEL COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vb.add_child(title)

	_complete_time_label = Label.new()
	_complete_time_label.text = ""
	_complete_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_time_label.add_theme_font_size_override("font_size", 22)
	vb.add_child(_complete_time_label)

	var next_btn := Button.new()
	next_btn.text = "Next Level"
	next_btn.pressed.connect(_on_next_level)
	vb.add_child(next_btn)
	_next_btn = next_btn

	var restart_btn := Button.new()
	restart_btn.text = "Retry"
	restart_btn.pressed.connect(_on_restart)
	vb.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Back to Menu"
	menu_btn.pressed.connect(_on_back_to_menu)
	vb.add_child(menu_btn)

	# Hide the CENTER — see _build_pause_panel for why.
	_complete_center.visible = false
	add_child(_complete_center)


func _fullscreen_center(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP


func _hide_all() -> void:
	_root_panel.visible = false
	_hint_label.visible = false
	_pause_center.visible = false
	_complete_center.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and LevelManager.get_current_level_id() != "":
		_toggle_pause()
	elif event.is_action_pressed(&"reset") and not _is_paused:
		if LevelManager.get_current_level_id() != "":
			LevelManager.reload_current()


func _toggle_pause() -> void:
	if _complete_center.visible:
		return
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_pause_center.visible = _is_paused
	if _is_paused:
		LevelTimer.pause_timer()
	else:
		LevelTimer.resume_timer()


func _on_restart() -> void:
	_is_paused = false
	get_tree().paused = false
	_complete_center.visible = false
	_pause_center.visible = false
	LevelManager.reload_current()


func _on_back_to_menu() -> void:
	_is_paused = false
	get_tree().paused = false
	_complete_center.visible = false
	_pause_center.visible = false
	LevelManager.go_to_menu()


func _on_next_level() -> void:
	_is_paused = false
	get_tree().paused = false
	_complete_center.visible = false
	LevelManager.load_next_level()


func _on_level_started(level_id: String) -> void:
	# Reset pause state — a level transition (especially the auto-reload after
	# failure) may have happened while the tree was paused, and SceneTree.paused
	# persists across scene changes.
	_is_paused = false
	get_tree().paused = false
	_root_panel.visible = true
	_hint_label.visible = true
	_complete_center.visible = false
	_pause_center.visible = false
	_is_countdown = LevelTimer.is_countdown()
	var best: float = SaveManager.get_best_time(level_id)
	if _is_countdown:
		_mode_label.text = "Countdown — reach the goal before time runs out"
		_best_label.text = "Best: %s left" % (_fmt(best) if is_finite(best) else "--:--.---")
		_timer_label.add_theme_color_override("font_color", _OK_COLOR)
	else:
		_mode_label.text = "Count Up — go fast!"
		_best_label.text = "Best: %s" % (_fmt(best) if is_finite(best) else "--:--.---")
		_timer_label.add_theme_color_override("font_color", _OK_COLOR)
	_hint_label.text = _hint_for(level_id)
	_progress_label.text = ""


func _on_level_completed(_level_id: String, time_seconds: float) -> void:
	get_tree().paused = true
	_complete_center.visible = true
	var best: float = SaveManager.get_best_time(_level_id)
	# Hide "Next Level" button if this was the final level.
	_next_btn.visible = LevelManager.get_next_level_id() != ""
	if _is_countdown:
		_complete_time_label.text = "Time left: %s\nBest: %s left" % [_fmt(time_seconds), _fmt(best) if is_finite(best) else "--:--.---"]
	else:
		_complete_time_label.text = "Time: %s\nBest: %s" % [_fmt(time_seconds), _fmt(best) if is_finite(best) else "--:--.---"]


func _on_objective_progress(_ratio: float, text: String) -> void:
	_progress_label.text = text


func _on_timer_tick(display_time: float) -> void:
	if _is_countdown:
		if display_time <= 0.01:
			_timer_label.text = "TIME UP"
			_timer_label.add_theme_color_override("font_color", _WARN_COLOR)
		else:
			_timer_label.text = _fmt(display_time)
			# Turn red in the final 10 seconds.
			var col: Color = _WARN_COLOR if display_time < 10.0 else _OK_COLOR
			_timer_label.add_theme_color_override("font_color", col)
	else:
		_timer_label.text = _fmt(display_time)


func _hint_for(level_id: String) -> String:
	match level_id:
		"level_01_drag":
			return "Drag & Drop: Click and drag the boxes into the DROP ZONE.   |   Esc: Pause   R: Reset"
		"level_02_platform":
			return "Platformer: A/D or Arrows to move, Space to jump.   |   Esc: Pause   R: Reset"
		"level_03_topdown":
			return "Top-Down: WASD or Arrows to move.   |   Esc: Pause   R: Reset"
		_:
			return "Esc: Pause   R: Reset"


func _fmt(seconds: float) -> String:
	var s: float = max(seconds, 0.0)
	var mins: int = int(s) / 60
	var secs: int = int(s) % 60
	var ms: int = int(fmod(s, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [mins, secs, ms]
