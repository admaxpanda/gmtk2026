extends Control
## Level selection screen. Reads LevelManager's runtime registry and builds
## a grid of level cards dynamically. Supports unlock cascade, best-time
## display, and refreshes on save_written signal.
##
## Thumbnails are generated at runtime by loading each level scene into an
## offscreen SubViewport, rendering one frame, and capturing the result as
## an ImageTexture. Cached thumbnails survive _populate_cards refreshes.

var _grid: GridContainer
var _progress_label: Label
var _thumbnail_cache: Dictionary = {}  # level_id -> ImageTexture
var _is_populating: bool = false       # guard against reentrant _populate_cards
var _gpu_available: bool = true        # detect at _ready if GPU is available


func _ready() -> void:
	# Detect headless environment via DisplayServer (OS.has_feature("headless")
	# is unreliable in Godot 4.6 — returns false even with --headless flag).
	# In headless mode, SubViewport rendering fails, so skip it entirely.
	_gpu_available = DisplayServer.get_name() != "headless"
	_build_ui()
	SignalBus.save_written.connect(_on_save_written)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.11, 0.16)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.offset_left = 80
	root.offset_right = -80
	root.offset_top = 40
	root.offset_bottom = -40
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var title := Label.new()
	title.text = "Select Level"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	root.add_child(title)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 16)
	_progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	root.add_child(_progress_label)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 24)
	center.add_child(_grid)
	root.add_child(center)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(160, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	root.add_child(back_btn)

	_populate_cards()


func _populate_cards() -> void:
	if _is_populating:
		return
	_is_populating = true

	for child in _grid.get_children():
		child.free()

	var progress: Dictionary = LevelManager.get_progress()
	_progress_label.text = "Progress: %d / %d" % [progress["completed"], progress["total"]]

	for level_id in LevelManager.get_level_ids():
		var card: Control = await _make_card(level_id)
		_grid.add_child(card)

	_is_populating = false


func _make_card(level_id: String) -> Control:
	var meta: Dictionary = LevelManager.get_level_metadata(level_id)
	var unlocked: bool = LevelManager.is_level_unlocked(level_id)
	var is_countdown: bool = meta.get("timer_mode", "count_up") == "count_down"
	var time_limit: float = float(meta.get("time_limit", 0.0))

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.15, 0.20)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	if not unlocked:
		card.modulate = Color(0.5, 0.5, 0.5)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	# Thumbnail (160x90, centered) — generated at runtime via SubViewport.
	var thumb: Control = await _make_thumbnail(level_id, unlocked)
	vb.add_child(thumb)

	# Title
	var title := Label.new()
	title.text = meta.get("title", level_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = meta.get("subtitle", "")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vb.add_child(subtitle)

	# Timer mode
	var mode := Label.new()
	if is_countdown:
		mode.text = "Count Down %ds" % int(time_limit)
	else:
		mode.text = "Count Up"
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode.add_theme_font_size_override("font_size", 14)
	mode.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	vb.add_child(mode)

	# Best time
	var best := Label.new()
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best.add_theme_font_size_override("font_size", 14)
	var best_time: float = SaveManager.get_best_time(level_id)
	if SaveManager.has_level_data(level_id) and is_finite(best_time):
		var best_text: String = "Best: " + _format_time(best_time)
		if is_countdown:
			best_text += " remaining"
		best.text = best_text
		best.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	else:
		best.text = "Best: --"
		best.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vb.add_child(best)

	# Play button
	var play_btn := Button.new()
	play_btn.custom_minimum_size = Vector2(140, 40)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if unlocked:
		play_btn.text = "Play"
		play_btn.disabled = false
		play_btn.pressed.connect(func(): LevelManager.load_level(level_id))
	else:
		play_btn.text = "Locked"
		play_btn.disabled = true
	vb.add_child(play_btn)

	return card


## Generates a level thumbnail at runtime using an offscreen SubViewport.
## The level scene is loaded, rendered for one frame, and the result is
## captured as an ImageTexture (cached per level_id for reuse).
## Falls back to placeholder if rendering fails (e.g., headless environment).
func _make_thumbnail(level_id: String, unlocked: bool) -> Control:
	# Return cached texture if available.
	if _thumbnail_cache.has(level_id):
		var tex: ImageTexture = _thumbnail_cache[level_id]
		return _make_thumb_rect(tex, unlocked)

	# Headless environment (no GPU): skip SubViewport entirely, use placeholder.
	if not _gpu_available:
		return _make_placeholder(unlocked)

	var scene_path: String = LevelManager.get_level_path(level_id)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return _make_placeholder(unlocked)

	var packed: PackedScene = load(scene_path)
	if packed == null:
		return _make_placeholder(unlocked)

	# Create offscreen SubViewport to render the level scene.
	# 640x360 is 2x the 160x90 display size — sharp enough for hi-DPI without
	# the 4x render cost of 1280x720.
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.transparent_bg = false
	add_child(vp)

	var instance := packed.instantiate()
	if instance == null:
		vp.queue_free()
		return _make_placeholder(unlocked)
	# Disable processing so child nodes (PlayerPlatformer, etc.) don't fall or
	# run game logic during the capture frames. _ready still runs and builds
	# visuals; we just block _process/_physics_process.
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	vp.add_child(instance)

	# One frame for _ready to run and build visuals (process disabled blocks
	# _process/_physics_process but _ready still fires on add_child).
	await get_tree().process_frame
	# Re-enable for one frame so the SubViewport's UPDATE_ONCE renders the
	# fully-built scene.
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().process_frame

	# Capture the rendered frame.
	var img: Image = vp.get_texture().get_image()
	if img == null:
		# Headless environment (no GPU) — fallback to placeholder.
		instance.queue_free()
		vp.queue_free()
		return _make_placeholder(unlocked)

	# Resize to thumbnail resolution (160x90 display size).
	img.resize(160, 90, Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(img)

	# Free the offscreen viewport and instance.
	instance.queue_free()
	vp.queue_free()

	# Cache for subsequent refreshes.
	_thumbnail_cache[level_id] = tex

	return _make_thumb_rect(tex, unlocked)


func _make_thumb_rect(tex: ImageTexture, unlocked: bool) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(160, 90)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		rect.modulate = Color(0.5, 0.5, 0.5)
	return rect


func _make_placeholder(unlocked: bool) -> Control:
	var placeholder := ColorRect.new()
	if unlocked:
		placeholder.color = Color(0.2, 0.3, 0.5)
	else:
		placeholder.color = Color(0.12, 0.12, 0.14)
	placeholder.custom_minimum_size = Vector2(160, 90)
	placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return placeholder


func _format_time(seconds: float) -> String:
	var s: float = max(seconds, 0.0)
	var mins: int = int(s) / 60
	var secs: int = int(s) % 60
	var ms: int = int(fmod(s, 1.0) * 1000)
	return "%02d:%02d.%03d" % [mins, secs, ms]


func _on_save_written() -> void:
	_populate_cards()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
