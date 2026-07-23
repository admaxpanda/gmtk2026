extends Node2D
## NinePatchRect 9-slice demonstration.
## A 64x64 test texture (distinct colored corners + yellow border) is generated
## in code, then shown two ways:
##   - Left:  raw TextureRect (source, scaled 4x)
##   - Right: NinePatchRect stretched to a live-adjustable size
## Six sliders control the 4 patch margins + preview width/height; a button
## cycles the axis stretch mode. Corners stay fixed while edges/center stretch.

const SceneHelpers = preload("res://feature/core/scene_helpers.gd")

const TEX_SIZE: int = 64
const CORNER: int = 12   # colored corner block size in source texture

var _texture: ImageTexture
var _nine_patch: NinePatchRect
var _info_label: Label
var _sm_btn: Button

# Patch margins (px in source texture)
var _p_left: int = 16
var _p_right: int = 16
var _p_top: int = 16
var _p_bottom: int = 16

# Preview size
var _pv_w: int = 440
var _pv_h: int = 300

# Stretch mode cycle
var _stretch_modes: Array = [
	[NinePatchRect.AXIS_STRETCH_MODE_STRETCH, "STRETCH"],
	[NinePatchRect.AXIS_STRETCH_MODE_TILE, "TILE"],
	[NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT, "TILE_FIT"],
]
var _stretch_idx: int = 0


func _ready() -> void:
	_texture = _make_test_texture()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://tests/test_menu.tscn")
	elif event.is_action_pressed("reset"):
		_reset_defaults()


# --- Texture generation ---

func _make_test_texture() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	# Center fill
	img.fill(Color(0.18, 0.22, 0.32, 1.0))
	# Yellow border so edges are visible when stretching
	var border_col := Color(0.95, 0.85, 0.25, 1.0)
	for i in TEX_SIZE:
		img.set_pixel(i, 0, border_col)
		img.set_pixel(i, TEX_SIZE - 1, border_col)
		img.set_pixel(0, i, border_col)
		img.set_pixel(TEX_SIZE - 1, i, border_col)
	# 4 distinctly-colored corners — these must NOT stretch in a correct 9-slice
	var tl := Color(0.95, 0.30, 0.30, 1.0)  # red
	var tr := Color(0.30, 0.90, 0.30, 1.0)  # green
	var bl := Color(0.30, 0.45, 0.95, 1.0)  # blue
	var br := Color(0.95, 0.30, 0.95, 1.0)  # magenta
	for y in CORNER:
		for x in CORNER:
			img.set_pixel(x, y, tl)
			img.set_pixel(TEX_SIZE - 1 - x, y, tr)
			img.set_pixel(x, TEX_SIZE - 1 - y, bl)
			img.set_pixel(TEX_SIZE - 1 - x, TEX_SIZE - 1 - y, br)
	return ImageTexture.create_from_image(img)


# --- UI ---

func _build_ui() -> void:
	add_child(SceneHelpers.make_background(Vector2(1280, 720), Color(0.08, 0.09, 0.12)))

	add_child(SceneHelpers.make_label("NinePatchRect 9-Slice Test", Vector2(40, 20), 28, Color.WHITE))
	add_child(SceneHelpers.make_label("Corners (colored) stay fixed; edges + center stretch. Adjust margins live.", Vector2(40, 58), 16, Color(0.65, 0.65, 0.7)))

	# Source texture (scaled 4x for visibility)
	add_child(SceneHelpers.make_label("Source Texture (%dx%d, shown 4x)" % [TEX_SIZE, TEX_SIZE], Vector2(40, 100), 16, Color(0.85, 0.85, 0.9)))
	var src := TextureRect.new()
	src.texture = _texture
	src.position = Vector2(40, 130)
	src.scale = Vector2(4, 4)
	add_child(src)

	# NinePatchRect (live stretch)
	add_child(SceneHelpers.make_label("NinePatchRect (live stretch)", Vector2(380, 100), 16, Color(0.85, 0.85, 0.9)))
	_nine_patch = NinePatchRect.new()
	_nine_patch.texture = _texture
	_nine_patch.position = Vector2(380, 130)
	_nine_patch.size = Vector2(_pv_w, _pv_h)
	_apply_patch()
	add_child(_nine_patch)

	# Controls
	var y: int = 470
	_make_slider("p_left",   "Patch Left",   40,  y, 0, 30, _p_left)
	_make_slider("p_right",  "Patch Right",  280, y, 0, 30, _p_right)
	_make_slider("p_top",    "Patch Top",    520, y, 0, 30, _p_top)
	_make_slider("p_bottom", "Patch Bottom", 760, y, 0, 30, _p_bottom)

	y += 70
	_make_slider("pv_w", "Preview W", 40,  y, 64, 840, _pv_w)
	_make_slider("pv_h", "Preview H", 280, y, 64, 320, _pv_h)

	# Stretch mode cycle button
	_sm_btn = Button.new()
	_sm_btn.position = Vector2(520, y)
	_sm_btn.custom_minimum_size = Vector2(220, 40)
	_update_sm_btn_text()
	_sm_btn.pressed.connect(_cycle_stretch_mode)
	add_child(_sm_btn)

	# Info label
	_info_label = Label.new()
	_info_label.position = Vector2(760, y)
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	add_child(_info_label)

	# Nav buttons
	var back_btn := SceneHelpers.make_button("Back to Test Menu (Esc)", Vector2(40, 660))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://tests/test_menu.tscn"))
	add_child(back_btn)

	var reset_btn := SceneHelpers.make_button("Reset (R)", Vector2(280, 660))
	reset_btn.pressed.connect(_reset_defaults)
	add_child(reset_btn)

	_update_info()


func _make_slider(key: String, label_text: String, x: int, y: int, min_v: int, max_v: int, val: int) -> void:
	var lbl := Label.new()
	lbl.text = "%s: %d" % [label_text, val]
	lbl.position = Vector2(x, y)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	add_child(lbl)

	var sl := HSlider.new()
	sl.position = Vector2(x, y + 24)
	sl.min_value = min_v
	sl.max_value = max_v
	sl.value = val
	sl.step = 1
	sl.custom_minimum_size = Vector2(220, 20)
	# Capture key + label_text + lbl by value (function params / locals → safe).
	sl.value_changed.connect(func(v: float):
		lbl.text = "%s: %d" % [label_text, int(v)]
		_on_param_changed(key, int(v))
	)
	add_child(sl)


# --- State updates ---

func _on_param_changed(key: String, v: int) -> void:
	match key:
		"p_left":   _p_left = v
		"p_right":  _p_right = v
		"p_top":    _p_top = v
		"p_bottom": _p_bottom = v
		"pv_w":     _pv_w = v
		"pv_h":     _pv_h = v
	_apply_patch()
	_update_info()


func _apply_patch() -> void:
	_nine_patch.patch_margin_left = _p_left
	_nine_patch.patch_margin_right = _p_right
	_nine_patch.patch_margin_top = _p_top
	_nine_patch.patch_margin_bottom = _p_bottom
	_nine_patch.size = Vector2(_pv_w, _pv_h)
	# Godot 4.6.3 applies a strict type check on enum-typed properties and
	# rejects direct int assignment ("Invalid assignment ... with value of type
	# 'int'"). Use set() with the property path to assign via Variant dispatch.
	var mode = _stretch_modes[_stretch_idx][0]
	_nine_patch.set("axis_stretch_mode_horizontal", mode)
	_nine_patch.set("axis_stretch_mode_vertical", mode)


func _cycle_stretch_mode() -> void:
	_stretch_idx = (_stretch_idx + 1) % _stretch_modes.size()
	_update_sm_btn_text()
	_apply_patch()
	_update_info()


func _update_sm_btn_text() -> void:
	_sm_btn.text = "Mode: %s" % _stretch_modes[_stretch_idx][1]


func _update_info() -> void:
	_info_label.text = "LRTB=%d/%d/%d/%d  size=%dx%d  %s" % [
		_p_left, _p_right, _p_top, _p_bottom, _pv_w, _pv_h,
		_stretch_modes[_stretch_idx][1]
	]


func _reset_defaults() -> void:
	# reload_current_scene re-runs _ready, which restores all field defaults
	# (16/16/16/16/440/300/stretch_idx=0). No need to assign here — those lines
	# would be overwritten by _ready anyway.
	get_tree().reload_current_scene()
