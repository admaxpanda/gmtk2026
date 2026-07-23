class_name SceneHelpers
## Static helpers for building common nodes procedurally. Used by test scenes
## (and available to any scene) to avoid duplicating boilerplate.

static func make_solid(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1 << 1  # solid
	body.collision_mask = 0

	var rect := ColorRect.new()
	rect.size = size
	rect.color = color
	rect.position = -size * 0.5
	body.add_child(rect)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	return body


static func make_label(text: String, pos: Vector2, size: int = 18, color: Color = Color(0.9, 0.9, 0.9)) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


static func make_button(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	return btn


static func make_background(size: Vector2, color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = color
	bg.size = size
	bg.position = Vector2.ZERO
	# MUST ignore mouse events — otherwise this full-screen ColorRect (default
	# mouse_filter = STOP) eats every click before Area2D.input_event can fire,
	# making all Draggable / clickable Area2Ds unresponsive.
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg
