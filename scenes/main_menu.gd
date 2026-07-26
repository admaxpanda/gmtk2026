extends Control
## Main menu entry screen. Shows only a "Start Game" button that leads to
## the level selection screen (res://scenes/level_select.tscn).

const LEVEL_SELECT_SCENE := "res://scenes/level_select.tscn"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = preload("res://ui/main_menu/background.png")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Dark overlay so the title/button stay readable over the art.
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.10, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "GMTK COUNTDOWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	var start_btn := Button.new()
	start_btn.text = "Start Game"
	start_btn.custom_minimum_size = Vector2(280, 76)
	start_btn.add_theme_font_size_override("font_size", 30)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
