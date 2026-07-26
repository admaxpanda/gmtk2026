class_name TrashBin
extends Area2D
## Drop zone for discarding the virtual timer.
## When VirtualTimer is dropped on this, triggers LevelTimer.truncate_to_units().
##
## Visual: A customizable icon/symbol representing a trash bin.
## Can be decorative (Level 1) or functional (Level 2).

@export var bin_size: Vector2 = Vector2(100, 100)
@export var icon_text: String = "🗑️"  # Placeholder symbol, can be customized
@export var icon_size: int = 48
@export var bg_color: Color = Color(0.18, 0.12, 0.12, 0.6)
@export var icon_color: Color = Color(0.85, 0.85, 0.85)
@export var is_functional: bool = true  # If false, just decorative (Level 1)

var _panel: PanelContainer
var _label: Label
var _is_hovered: bool = false


func _ready() -> void:
	# Position will be set by parent (right-bottom corner)
	collision_layer = 1 << 4  # drop zone layer
	collision_mask = 1 << 3  # detect draggable/virtual timer
	monitoring = is_functional
	# Must be monitorable so draggables (which monitor the drop-zone layer) can
	# detect this bin via get_overlapping_areas() on drop. Decorative bins stay
	# non-interactive because is_functional is false (monitoring off) — but they
	# still aren't a valid drop target since monitorable follows is_functional too.
	monitorable = is_functional

	_build_ui()

	if is_functional:
		area_entered.connect(_on_area_entered)
		area_exited.connect(_on_area_exited)


func _build_ui() -> void:
	# Panel container for background
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = bin_size
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Label for icon
	_label = Label.new()
	_label.text = icon_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", icon_size)
	_label.add_theme_color_override("font_color", icon_color)
	_panel.add_child(_label)

	# Collision shape
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bin_size
	col.shape = shape
	add_child(col)


func _on_area_entered(area: Area2D) -> void:
	if area is VirtualTimer:
		_is_hovered = true
		# Visual feedback - highlight when virtual timer hovers
		_label.add_theme_color_override("font_color", icon_color.lightened(0.3))
		_panel.scale = Vector2(1.1, 1.1)


func _on_area_exited(area: Area2D) -> void:
	if area is VirtualTimer:
		_is_hovered = false
		_label.add_theme_color_override("font_color", icon_color)
		_panel.scale = Vector2.ONE


func is_hovered() -> bool:
	return _is_hovered