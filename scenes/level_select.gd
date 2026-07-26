extends Control
## Level selection screen. Reads LevelManager's runtime registry and builds
## a responsive flow of level cards dynamically. Supports unlock cascade and
## refreshes on save_written signal.
##
## Thumbnails are generated at runtime by loading each level scene into an
## offscreen SubViewport, rendering one frame, and capturing the result as
## an ImageTexture. Cached thumbnails survive _populate_cards refreshes.

var _grid: GridContainer
var _scroll: ScrollContainer
var _progress_label: Label
var _bg: ColorRect
var _title: Label
var _back_btn: Button
var _thumbnail_cache: Dictionary = {}  # level_id -> ImageTexture
var _is_populating: bool = false       # guard against reentrant _populate_cards
var _gpu_available: bool = true        # detect at _ready if GPU is available
var _card_size := Vector2(360, 240)     # computed by _layout_grid to fill the page


func _ready() -> void:
	var _dbg := FileAccess.open("user://_dbg_ready.txt", FileAccess.WRITE)
	if _dbg != null:
		_dbg.store_line("READY_ENTERED")
		_dbg.close()
	# Detect headless environment via DisplayServer (OS.has_feature("headless")
	# is unreliable in Godot 4.6 — returns false even with --headless flag).
	# In headless mode, SubViewport rendering fails, so skip it entirely.
	_gpu_available = DisplayServer.get_name() != "headless"
	_build_ui()
	SignalBus.save_written.connect(_on_save_written)


func _build_ui() -> void:
	# Build plain Controls and lay them out explicitly from the viewport size
	# in _relayout(). We deliberately do NOT rely on the scene-root Control
	# filling the window via anchor presets (that proved unreliable in practice
	# — the root kept resolving to a 0x0 rect, so anchored children collapsed
	# and the title stopped being full-width/centered). Instead every element
	# gets an explicit position/size relative to the parent origin, computed
	# from get_viewport().size, so layout is deterministic and independent of
	# container/anchor quirks.
	_bg = ColorRect.new()
	_bg.color = Color(0.10, 0.11, 0.16)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_title = Label.new()
	_title.text = "Select Level"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 44)
	add_child(_title)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 16)
	_progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	add_child(_progress_label)

	# Scrollable region for the level cards. Native mouse-wheel vertical
	# scrolling; horizontal scrolling disabled (the grid always fits width).
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)

	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 24)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Do NOT expand vertically: inside a ScrollContainer the grid must size to
	# its content so it can exceed the viewport and become scrollable. The
	# fill-vs-scroll decision is made per-layout in _layout_grid().
	_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_scroll.add_child(_grid)

	_back_btn = Button.new()
	_back_btn.text = "Back"
	_back_btn.custom_minimum_size = Vector2(160, 40)
	_back_btn.pressed.connect(_on_back_pressed)
	add_child(_back_btn)

	_relayout()
	get_viewport().size_changed.connect(_relayout)
	_populate_cards()


## Positions every UI element explicitly from the current viewport size.
## Called once at build time and on every window resize. Using explicit
## position/size with TOP_LEFT anchors means layout never depends on the root
## Control filling the window.
func _relayout() -> void:
	if _bg == null or _title == null or _grid == null or _scroll == null or _back_btn == null:
		return
	var vps: Vector2 = _viewport_size()
	var w: float = vps.x
	var h: float = vps.y

	# Background covers the whole screen.
	_bg.set_anchors_preset(PRESET_TOP_LEFT)
	_bg.position = Vector2(0, 0)
	_bg.custom_minimum_size = vps

	# Title: full width at the top, text centered horizontally.
	# NOTE: Labels/GridContainers recompute their size from content, so we must
	# enforce dimensions via custom_minimum_size (assigning .size is overridden
	# by the layout pass). With a full-width min size and horizontal_alignment
	# CENTER, the title text is reliably centered.
	_title.set_anchors_preset(PRESET_TOP_LEFT)
	_title.position = Vector2(0, 14)
	_title.custom_minimum_size = Vector2(w, 56)

	# Progress label directly under the title, full width.
	_progress_label.set_anchors_preset(PRESET_TOP_LEFT)
	_progress_label.position = Vector2(0, 74)
	_progress_label.custom_minimum_size = Vector2(w, 26)

	# Scroll region: fills the area between the title band (top 100px) and the
	# back button (bottom 64px). The grid inside fills the scroll width and
	# scrolls vertically when there are more cards than fit on screen.
	_scroll.set_anchors_preset(PRESET_TOP_LEFT)
	_scroll.position = Vector2(24, 100)
	_scroll.custom_minimum_size = Vector2(w - 48, h - 164)
	# Grid fills the scroll width; its height is content-driven so the scroll
	# region can grow past the viewport and scroll when levels overflow.
	_grid.custom_minimum_size = Vector2(w - 48, 0)

	# Back button: horizontally centered near the bottom.
	_back_btn.set_anchors_preset(PRESET_TOP_LEFT)
	_back_btn.position = Vector2((w - 160) / 2.0, h - 52)
	_back_btn.custom_minimum_size = Vector2(160, 40)

	# Recompute card sizes to fill the (now explicit) grid rect.
	_layout_grid()


## Returns the current viewport size, falling back to the project's designed
## 1920x1080 resolution when the viewport is not yet sized (e.g. during _ready).
## Shared by _relayout and _layout_grid so both reason about the same area.
func _viewport_size() -> Vector2:
	var vp := get_viewport()
	var vps: Vector2 = vp.size
	if vps.x <= 0 or vps.y <= 0:
		vps = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width", 1920),
			ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return vps


func _populate_cards() -> void:
	if _is_populating:
		return
	_is_populating = true

	for child in _grid.get_children():
		child.free()

	var progress: Dictionary = LevelManager.get_progress()
	_progress_label.text = "Progress: %d / %d" % [progress["completed"], progress["total"]]

	var _pf := FileAccess.open("user://_dbg_ids.txt", FileAccess.WRITE)
	if _pf != null:
		var ids: Array = LevelManager.get_level_ids()
		_pf.store_line("IDS_COUNT=%d" % ids.size())
		for iid in ids:
			_pf.store_line("  " + str(iid))
		_pf.close()

	for level_id in LevelManager.get_level_ids():
		var card: Control = await _make_card(level_id)
		_grid.add_child(card)

	# Wait one frame so the grid has a valid (laid-out) size, then size every
	# card to fill the page exactly.
	await get_tree().process_frame
	_layout_grid()

	_is_populating = false


## Computes the column count and exact card size needed to fill the grid
## area (the whole screen minus the title and back-button bands). Picks the
## column count whose cards are most square so they never stretch absurdly
## wide or tall, then sizes every card to that exact pixel size.
##
## Fill-vs-scroll: when the cards fit the available height the grid expands to
## fill the screen (no scrollbar). When they would overflow, the grid shrinks
## to its content height so the ScrollContainer actually has something to
## scroll — this is what makes the mouse wheel work.
func _layout_grid() -> void:
	var _p := FileAccess.open("user://_dbg_lg_enter.txt", FileAccess.WRITE)
	if _p != null:
		_p.store_line("LG_ENTER grid=%s scroll=%s" % [_grid != null, _scroll != null])
		_p.close()
	if _grid == null or _scroll == null:
		return
	var n := LevelManager.get_level_ids().size()
	if n == 0:
		return
	# Reason about the designed scroll area directly (not _grid.size, which is
	# circular: it depends on the very flags we set here).
	var vps: Vector2 = _viewport_size()
	var grid_w := vps.x - 48.0
	var grid_h := vps.y - 164.0
	if grid_w <= 0 or grid_h <= 0:
		return
	var hsep := 24
	var vsep := 24

	var best_cols := 1
	var best_score := -1.0
	for c in range(1, n + 1):
		var r := int(ceil(float(n) / float(c)))
		var cw := (grid_w - (c - 1) * hsep) / float(c)
		var ch := (grid_h - (r - 1) * vsep) / float(r)
		if cw <= 0.0 or ch <= 0.0:
			continue
		var score: float = min(cw, ch)
		if score > best_score:
			best_score = score
			best_cols = c

	var rows := int(ceil(float(n) / float(best_cols)))
	var card_w := (grid_w - (best_cols - 1) * hsep) / float(best_cols)
	# Fill the height when it keeps cards reasonable; cap so a single row of few
	# levels does not become a giant card.
	var card_h := (grid_h - (rows - 1) * vsep) / float(rows)
	card_h = min(card_h, 520.0)
	card_w = min(card_w, 640.0)

	# Decide whether the grid overflows the scroll viewport.
	var needed_h := rows * card_h + (rows - 1) * vsep
	if needed_h <= grid_h + 1.0:
		# Fits: expand to fill the screen, no scrollbar needed.
		_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		# Overflows: shrink to content height so the ScrollContainer scrolls.
		_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_card_size = Vector2(card_w, card_h)
	_grid.columns = best_cols
	# Preview is always 16:9; compute its exact height from the card's inner
	# width so the image fills the box with no offset or letterboxing.
	var inner_w := card_w - 28.0  # minus the PanelContainer content margins (14*2)
	var preview_h := inner_w * 9.0 / 16.0
	for card in _grid.get_children():
		card.custom_minimum_size = _card_size
		var rb = card.get_meta("ratio_box", null)
		if rb != null:
			rb.custom_minimum_size = Vector2(0, preview_h)
	var f := FileAccess.open("user://_dbg_layout.txt", FileAccess.WRITE)
	if f != null:
		f.store_line("DBG_LAYOUT n=%d cols=%d card=%.0f,%.0f preview_h=%.0f vflag=%d needed_h=%.0f grid_h=%.0f" % [n, best_cols, card_w, card_h, preview_h, _grid.size_flags_vertical, needed_h, grid_h])
		f.close()


func _make_card(level_id: String) -> Control:
	var meta: Dictionary = LevelManager.get_level_metadata(level_id)
	var index: int = LevelManager.get_level_index(level_id)
	var unlocked: bool = LevelManager.is_level_unlocked(level_id)
	var completed: bool = SaveManager.is_level_completed(level_id)

	var card := PanelContainer.new()
	# Exact size is set by _layout_grid to fill the page; this is just the
	# initial value used before the first layout pass.
	card.custom_minimum_size = _card_size
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.15, 0.20)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	if not unlocked:
		card.modulate = Color(0.5, 0.5, 0.5)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	# Let clicks fall through to the card so the whole card is clickable.
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vb)

	# Top row: level number on the left, status marker on the right.
	var top := HBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vb.add_child(top)

	var num := Label.new()
	num.text = "%02d" % (index + 1)
	num.add_theme_font_size_override("font_size", 22)
	num.add_theme_color_override("font_color", Color(0.65, 0.68, 0.78))
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(num)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	if completed:
		var done := Label.new()
		done.text = "✓"
		done.add_theme_font_size_override("font_size", 26)
		done.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
		done.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(done)
	elif not unlocked:
		var lock := Label.new()
		lock.text = "Locked"
		lock.add_theme_font_size_override("font_size", 14)
		lock.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(lock)

	# Thumbnail: a clean 16:9 rectangular preview. The AspectRatioContainer
	# keeps it at a fixed aspect ratio regardless of card width, so the preview
	# is always a proper rectangle and never stretched/distorted. Its height is
	# set in _layout_grid from the card width; SHRINK vertical keeps the VBox
	# from stretching it into a letterboxed box.
	var thumb: Control = await _make_thumbnail(level_id, unlocked)
	var ratio_box := AspectRatioContainer.new()
	ratio_box.ratio = 16.0 / 9.0
	ratio_box.stretch_mode = AspectRatioContainer.STRETCH_COVER
	ratio_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ratio_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ratio_box.add_child(thumb)
	vb.add_child(ratio_box)
	# Reference used by _layout_grid to set the exact 16:9 preview height.
	card.set_meta("ratio_box", ratio_box)

	# Level title — the primary text on the card.
	var title := Label.new()
	title.text = meta.get("title", level_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(title)

	# Elastic spacer: absorbs any leftover card height so the preview box stays
	# exactly 16:9 (no stretch/letterbox) whether the grid fills the screen or
	# scrolls.
	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(bottom_spacer)

	# The whole card launches the level (replaces the old Play button).
	# Locked levels stay unclickable and remain dimmed. Unlocked cards get a
	# subtle hover highlight.
	if unlocked:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed \
					and event.button_index == MOUSE_BUTTON_LEFT:
				LevelManager.load_level(level_id))
		card.mouse_entered.connect(func(): _apply_card_hover(style, true))
		card.mouse_exited.connect(func(): _apply_card_hover(style, false))
	else:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return card


func _apply_card_hover(style: StyleBoxFlat, hovered: bool) -> void:
	if hovered:
		style.bg_color = Color(0.21, 0.23, 0.32)
		style.set_border_width_all(2)
		style.border_color = Color(0.35, 0.55, 0.9)
	else:
		style.bg_color = Color(0.14, 0.15, 0.20)
		style.set_border_width_all(0)
		style.border_color = Color(0, 0, 0, 0)


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
	# Size it to the game's design viewport (1920x1080) so the captured region
	# matches exactly what the player sees when the level is played. Levels have
	# no Camera2D, so a SubViewport smaller than the design viewport would only
	# render the top-left sliver of the level (heavily zoomed/cropped).
	var vp_w: int = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)
	var vp_h: int = ProjectSettings.get_setting("display/window/size/viewport_height", 1080)
	var vp := SubViewport.new()
	vp.size = Vector2i(vp_w, vp_h)
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

	# Resize to a higher resolution (640x360) so larger cards stay crisp.
	img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
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
	# EXPAND_FIT_WIDTH scales the texture to the box width keeping its 16:9
	# aspect, so it covers the AspectRatioContainer box exactly (height ends up
	# equal to the box height) with no offset. EXPAND_IGNORE_SIZE would keep the
	# raw 640x360 size and drift off-center inside the box.
	rect.custom_minimum_size = Vector2(0, 0)
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	placeholder.custom_minimum_size = Vector2(0, 0)
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return placeholder


func _on_save_written() -> void:
	_populate_cards()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
