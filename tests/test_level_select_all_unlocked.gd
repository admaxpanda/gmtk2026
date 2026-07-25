extends Control
## 开发模式关卡选择界面。强制所有关卡为解锁状态，用于测试和调试。
## 复用 level_select.gd 的 UI 构建逻辑，但跳过解锁检查。

var _grid: GridContainer
var _progress_label: Label
var _thumbnail_cache: Dictionary = {}  # level_id -> ImageTexture
var _is_populating: bool = false       # 防止重入 _populate_cards
var _gpu_available: bool = true        # 检测 GPU 是否可用


func _ready() -> void:
	# 启用开发模式：跳过关卡解锁检查
	LevelManager.set_dev_mode(true)
	# 检测 headless 环境（DisplayServer 检测比 OS.has_feature 更可靠）
	# 在 headless 模式下，SubViewport 渲染会失败，因此跳过
	_gpu_available = DisplayServer.get_name() != "headless"
	_build_ui()


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
	title.text = "Select Level (Dev Mode)"
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

	_progress_label.text = "Dev Mode - All Unlocked"

	for level_id in LevelManager.get_level_ids():
		var card: Control = await _make_card(level_id)
		_grid.add_child(card)

	_is_populating = false


func _make_card(level_id: String) -> Control:
	var meta: Dictionary = LevelManager.get_level_metadata(level_id)
	# 开发模式：强制所有关卡为解锁状态
	var unlocked: bool = true
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
	# 开发模式：不应用锁定变灰效果

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	# 缩略图 (160x90, 居中) — 运行时通过 SubViewport 生成
	var thumb: Control = await _make_thumbnail(level_id)
	vb.add_child(thumb)

	# 标题
	var title := Label.new()
	title.text = meta.get("title", level_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)

	# 副标题
	var subtitle := Label.new()
	subtitle.text = meta.get("subtitle", "")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vb.add_child(subtitle)

	# 计时模式
	var mode := Label.new()
	if is_countdown:
		mode.text = "Count Down %ds" % int(time_limit)
	else:
		mode.text = "Count Up"
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode.add_theme_font_size_override("font_size", 14)
	mode.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	vb.add_child(mode)

	# 最佳时间
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

	# Play 按钮（始终可点击）
	var play_btn := Button.new()
	play_btn.custom_minimum_size = Vector2(140, 40)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.text = "Play"
	play_btn.disabled = false
	play_btn.pressed.connect(func(): LevelManager.load_level(level_id))
	vb.add_child(play_btn)

	return card


## 通过离屏 SubViewport 运行时生成关卡缩略图。
## 关卡场景被加载、渲染一帧，结果作为 ImageTexture 捕获（按 level_id 缓存以复用）。
## 如果渲染失败（如 headless 环境），回退到占位符。
func _make_thumbnail(level_id: String) -> Control:
	# 返回缓存的纹理（如果可用）
	if _thumbnail_cache.has(level_id):
		var tex: ImageTexture = _thumbnail_cache[level_id]
		return _make_thumb_rect(tex)

	# Headless 环境（无 GPU）：跳过 SubViewport，使用占位符
	if not _gpu_available:
		return _make_placeholder()

	var scene_path: String = LevelManager.get_level_path(level_id)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return _make_placeholder()

	var packed: PackedScene = load(scene_path)
	if packed == null:
		return _make_placeholder()

	# 创建离屏 SubViewport 渲染关卡场景
	# 640x360 是 160x90 显示尺寸的 2 倍 — 对于 hi-DPI 足够清晰，
	# 而不需要 1280x720 的 4 倍渲染成本
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.transparent_bg = false
	add_child(vp)

	var instance := packed.instantiate()
	if instance == null:
		vp.queue_free()
		return _make_placeholder()
	# 禁用处理，使子节点（PlayerPlatformer 等）在捕获帧期间不会
	# 下落或运行游戏逻辑。_ready 仍会运行并构建视觉效果；
	# 我们只是阻止 _process/_physics_process
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	vp.add_child(instance)

	# 一帧让 _ready 运行并构建视觉效果（process disabled 阻止
	# _process/_physics_process，但 _ready 在 add_child 时仍会触发）
	await get_tree().process_frame
	# 重新启用一帧，让 SubViewport 的 UPDATE_ONCE 渲染
	# 完全构建的场景
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().process_frame

	# 捕获渲染的帧
	var img: Image = vp.get_texture().get_image()
	if img == null:
		# Headless 环境（无 GPU）— 回退到占位符
		instance.queue_free()
		vp.queue_free()
		return _make_placeholder()

	# 调整到缩略图分辨率（160x90 显示尺寸）
	img.resize(160, 90, Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(img)

	# 释放离屏 viewport 和实例
	instance.queue_free()
	vp.queue_free()

	# 缓存以供后续刷新使用
	_thumbnail_cache[level_id] = tex

	return _make_thumb_rect(tex)


func _make_thumb_rect(tex: ImageTexture) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(160, 90)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 开发模式：不应用锁定变灰效果
	return rect


func _make_placeholder() -> Control:
	var placeholder := ColorRect.new()
	placeholder.color = Color(0.2, 0.3, 0.5)
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


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()