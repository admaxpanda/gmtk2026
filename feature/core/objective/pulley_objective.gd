class_name PulleyObjective
extends LevelObjective
## Level 5 objective: Pulley.
## - Player controls a platformer character
## - A panel covers the button, blocking access
## - Player jumps on a pulley platform to sink it, raising the panel
## - Once the panel is raised, the button becomes clickable
## - The level completes only when the countdown reaches 0.00 AND the player
##   clicks the button within the win window. Reaching 0.00 without a winning
##   click FAILS the level (BaseLevel default — no longer overridden).

@export var player_start: Vector2 = Vector2(200, 920)  # Feet rest on the ground top (y=920) with the new bottom-at-origin box
@export var platform_position: Vector2 = Vector2(1150, 520)  # Moved to the right side, clear of the panel's x-range (>=1125); reach it via the step path below
@export var platform_sink_depth: float = 160.0  # 1:1 with panel_max_rise (true pulley)
@export var panel_position: Vector2 = Vector2(950, 785)  # Sits over the button, fully covering it when down
@export var panel_size: Vector2 = Vector2(170, 320)  # SlidingPanel visual size — tall enough to occlude the button
@export var panel_max_rise: float = 160.0  # Fully clears the button; == platform_sink_depth (1:1 pulley)
@export var panel_rise_ratio: float = 1.0  # TRUE 1:1 pulley: panel rises exactly as the platform sinks
@export var button_position: Vector2 = Vector2(950, 850)  # Bottom (radius 70) rests on the ground top (y=920), no longer sunk into it
@export var button_radius: float = 70.0
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var ground_y: float = 940.0
@export var pulley_top_y: float = 200.0  # Decorative pulley position
@export var win_tolerance: float = 0.25  # Click within this many seconds of 0.00 to win
@export var step_platforms: Array[Vector2] = [Vector2(360, 820), Vector2(560, 710), Vector2(760, 600), Vector2(840, 510), Vector2(1000, 445)]
# The last step (1000, 445) is a perch just ABOVE the raised panel's top — it lets
# the player hop over the panel "gate" (which blocks ground passage when down) to
# reach the pulley platform on the right. Tune the whole climb via this array.
@export var step_size: Vector2 = Vector2(170, 24)  # Size of each stepping platform in the jump path

var _player: PlayerPlatformer
var _platform: PulleyPlatform
var _panel: SlidingPanel
var _button: Area2D
var _time_label: Label  # Countdown shown ABOVE the button (level 1 stop-clock style)
var _ground: StaticBody2D
var _walls: StaticBody2D
var _platform_rope: Line2D  # Dynamic rope from pulley to platform
var _panel_rope: Line2D    # Dynamic rope from pulley to panel
var _pulley_top_y: float = 200.0  # Y position of pulley wheel
var _pulley_pos: Vector2 = Vector2.ZERO  # Center of the pulley wheel (rope anchor)
var _panel_raised: bool = false  # Live: is the panel currently fully raised?
var _button_circle: Polygon2D  # Button visual, recolored when clickable


func _ready() -> void:
	_build_ground()
	_build_walls()
	_build_pulley_visual()
	_build_panel()
	_build_platform()
	_build_path()
	_build_button()
	_build_player()
	_refresh_ropes()

	# F6 dev support
	if LevelManager.get_current_level_id() == "":
		var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
		LevelManager.begin_dev_test(level_id)

	_emit_progress()


func _on_timer_tick(display_time: float) -> void:
	if is_instance_valid(_time_label):
		_time_label.text = "%.2f" % max(display_time, 0.0)
	_update_button_state()
	_emit_progress()


## Called when the countdown reaches 0.00. BaseLevel fails the level here unless
## the objective was completed in the same frame (a click at ~0.00 wins before
## timed_out fires). Mirror level 1: snap the above-button countdown to 0.00.
func _on_timed_out() -> void:
	if is_instance_valid(_time_label):
		_time_label.text = "0.00"


func _build_ground() -> void:
	_ground = StaticBody2D.new()
	_ground.name = "Ground"
	_ground.position = Vector2(960, ground_y + 20)
	_ground.collision_layer = 1 << 1  # solid
	_ground.collision_mask = 0

	var rect := ColorRect.new()
	rect.size = Vector2(1920, 80)
	rect.color = Color(0.20, 0.22, 0.25)
	rect.position = -Vector2(960, 40)
	_ground.add_child(rect)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1920, 80)
	col.shape = shape
	_ground.add_child(col)

	add_child(_ground)


func _build_walls() -> void:
	# Left and right walls to keep player in bounds
	_walls = StaticBody2D.new()
	_walls.name = "Walls"
	_walls.collision_layer = 1 << 1
	_walls.collision_mask = 0

	# Left wall
	var left_col := CollisionShape2D.new()
	var left_shape := RectangleShape2D.new()
	left_shape.size = Vector2(40, 1080)
	left_col.shape = left_shape
	left_col.position = Vector2(-20, 540)
	_walls.add_child(left_col)

	# Right wall
	var right_col := CollisionShape2D.new()
	var right_shape := RectangleShape2D.new()
	right_shape.size = Vector2(40, 1080)
	right_col.shape = right_shape
	right_col.position = Vector2(1940, 540)
	_walls.add_child(right_col)

	# Ceiling
	var ceil_col := CollisionShape2D.new()
	var ceil_shape := RectangleShape2D.new()
	ceil_shape.size = Vector2(1920, 40)
	ceil_col.shape = ceil_shape
	ceil_col.position = Vector2(960, -20)
	_walls.add_child(ceil_col)

	add_child(_walls)


func _build_pulley_visual() -> void:
	# Decorative pulley: a wheel at top, with two rope segments running from the
	# wheel down to the platform and the panel (a proper pulley "V").
	var pulley_pos := Vector2((platform_position.x + panel_position.x) * 0.5, pulley_top_y)
	_pulley_top_y = pulley_pos.y
	_pulley_pos = pulley_pos

	# Pulley wheel
	var wheel := Polygon2D.new()
	wheel.polygon = _make_circle(20, 24)
	wheel.color = Color(0.45, 0.45, 0.50)
	wheel.position = pulley_pos
	add_child(wheel)

	# Rope from pulley wheel to platform (dynamic; anchored at the wheel)
	_platform_rope = Line2D.new()
	_platform_rope.width = 3
	_platform_rope.default_color = Color(0.65, 0.55, 0.40)
	_platform_rope.add_point(_pulley_pos)
	_platform_rope.add_point(Vector2(platform_position.x, platform_position.y))
	add_child(_platform_rope)

	# Rope from pulley wheel to panel (dynamic; anchored at the wheel)
	_panel_rope = Line2D.new()
	_panel_rope.width = 3
	_panel_rope.default_color = Color(0.65, 0.55, 0.40)
	_panel_rope.add_point(_pulley_pos)
	_panel_rope.add_point(Vector2(panel_position.x, panel_position.y - panel_size.y * 0.5))
	add_child(_panel_rope)


func _build_panel() -> void:
	_panel = SlidingPanel.new()
	_panel.position = panel_position
	_panel.max_rise = panel_max_rise
	_panel.panel_size = panel_size  # Make the visual/collision match the export
	# Draw the panel above the button so, when down, it fully occludes it.
	_panel.z_index = 1
	add_child(_panel)


func _build_platform() -> void:
	_platform = PulleyPlatform.new()
	_platform.position = platform_position
	_platform.sink_depth = platform_sink_depth
	_platform.moved.connect(_on_platform_moved)
	add_child(_platform)


## Builds the static stepping platforms the player jumps across to reach the
## raised pulley platform. Gaps stay within a fair jump given the buffed jump
## (~150px apex, ~240px reach): vertical ~100-112px, horizontal ~80-170px.
## The path is raised so the platform, when it sinks the full 160px (1:1 with
## the panel), lands at y~680 — clear of every step with no overlap.
## Tune via `step_platforms`.
func _build_path() -> void:
	for p in step_platforms:
		var body := StaticBody2D.new()
		body.name = "StepPlatform"
		body.position = p
		body.collision_layer = 1 << 1  # solid
		body.collision_mask = 0

		var rect := ColorRect.new()
		rect.size = step_size
		rect.color = Color(0.28, 0.30, 0.36)
		rect.position = -step_size * 0.5
		body.add_child(rect)

		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = step_size
		col.shape = shape
		body.add_child(col)

		add_child(body)


func _build_button() -> void:
	_button = Area2D.new()
	_button.name = "ClickButton"
	_button.position = button_position
	_button.input_pickable = false  # enabled only after the panel is raised
	_button.collision_layer = 1 << 2  # goal/button layer
	_button.collision_mask = 1 << 0  # detect player (for body_entered)
	_button.monitoring = true
	_button.monitorable = false
	_button.z_index = 2  # draw above the panel once revealed (level 1 style)

	# Round red button visual — always red, like StopClockObjective's button.
	# Hidden until the panel is raised (the panel covers it before that).
	_button_circle = Polygon2D.new()
	_button_circle.polygon = _make_circle(button_radius, 32)
	_button_circle.color = button_color
	_button_circle.visible = false
	_button.add_child(_button_circle)

	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = button_radius
	col.shape = shape
	_button.add_child(col)

	_button.body_entered.connect(_on_button_body_entered)
	_button.input_event.connect(_on_button_input)
	add_child(_button)

	# Countdown number ABOVE the button — same stop-clock presentation as level
	# 1. Always visible (z above the panel) so the player can pace the jump path
	# while the panel still covers the button, then click it at ~0.00.
	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 64)
	_time_label.add_theme_color_override("font_color", Color.WHITE)
	_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_label.size = Vector2(button_radius * 2.0, 80.0)
	_time_label.position = button_position + Vector2(-button_radius, -button_radius - 90.0)
	_time_label.z_index = 2
	_time_label.text = "%.2f" % max(LevelTimer.get_display_time(), 0.0)
	add_child(_time_label)

	# Connect to timer updates (timeout-fail is handled by BaseLevel).
	LevelTimer.tick.connect(_on_timer_tick)
	LevelTimer.timed_out.connect(_on_timed_out)

	_update_button_state()


## Match level 1's stop-clock button: always red, only becomes pickable (and
## visible) once the panel is raised and exposes it. No amber/green recolor —
## the win window is conveyed by the countdown number above the button.
func _update_button_state() -> void:
	var raised: bool = _panel_raised or (is_instance_valid(_panel) and _panel.is_fully_raised())
	_button.input_pickable = raised
	if is_instance_valid(_button_circle):
		_button_circle.visible = raised


## Win is allowed only once the panel is raised AND the countdown is inside the
## 0.00 win window (remaining <= win_tolerance, before timed_out fires). Clicks
## after the timer has expired do NOT win — the level has already failed.
func _can_win_now() -> bool:
	var raised: bool = _panel_raised or (is_instance_valid(_panel) and _panel.is_fully_raised())
	if not raised:
		return false
	return (not LevelTimer.has_timed_out()) and LevelTimer.get_remaining() <= win_tolerance


## Click-to-stop, identical to StopClockObjective: within the 0.00 win window the
## click wins; clicking too early (panel raised but countdown not yet at ~0) fails
## with "Too early!". A click while the panel still covers the button is ignored
## (the button is not pickable then).
func _on_button_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if _is_completed or _is_failed:
		return
	if not _button.input_pickable:  # panel still covers the button
		return
	if LevelTimer.has_timed_out():
		return
	if LevelTimer.get_remaining() <= win_tolerance:
		_complete()
	else:
		_fail("Too early!")


func _build_player() -> void:
	_player = PlayerPlatformer.new()
	_player.position = player_start
	# Level 5 tuning: the stepping-platform path starts with a ~132px gap from
	# the ground (940) to the first step top (~808), which exceeds the default
	# ~96px jump apex and makes the player snag on platform edges ("卡脚").
	# Bump jump velocity so the apex (~150px) clears that first gap with a fair
	# margin while keeping the climb tricky. Only this level is affected — the
	# exported default in PlayerPlatformer is left unchanged for other uses.
	_player.jump_velocity = -600.0
	add_child(_player)

	# Replace the placeholder blue square (PlayerPlatformer's "Visual" child)
	# with the assembled character sprite (arm/body/head/leg/eye).
	# The sprite's native size is ~126x418px; we scale it to fit the 36x52
	# collision box and align its feet to the box's bottom-center.
	var placeholder := _player.get_node_or_null("Visual")
	if is_instance_valid(placeholder):
		placeholder.queue_free()

	var player_scene := preload("res://ingame/player.tscn") as PackedScene
	if player_scene != null:
		var spr := player_scene.instantiate()
		spr.name = "PlayerSprite"
		var s := 0.29
		spr.scale = Vector2(s, s)
		# Sprite root-local: feet sit ~377px below the origin, visual center ~3px off x.
		spr.position = Vector2(-3.0 * s, -377.0 * s)
		_player.add_child(spr)
		var ap := spr.get_node_or_null("AnimationPlayer")
		if is_instance_valid(ap):
			ap.play("moving")


func _on_platform_moved(delta_y: float) -> void:
	# Panel tracks the platform both ways (real pulley): rises as the platform
	# sinks, descends back as the platform rises when the player steps off.
	# `_panel_raised` is a LIVE flag (not latched) so the button only stays
	# clickable while the panel is actually up.
	_panel.on_platform_moved(delta_y * panel_rise_ratio)
	_panel_raised = _panel.is_fully_raised()
	_refresh_ropes()
	_update_button_state()


## Re-anchor both rope segments to the pulley wheel and to the tops of the
## moving platform/panel, so the visual stays connected as they travel.
func _refresh_ropes() -> void:
	if _platform_rope == null or _panel_rope == null:
		return
	if is_instance_valid(_platform):
		_platform_rope.set_point_position(0, _pulley_pos)
		_platform_rope.set_point_position(1, Vector2(platform_position.x, _platform.position.y - _platform.platform_size.y * 0.5))
	if is_instance_valid(_panel):
		_panel_rope.set_point_position(0, _pulley_pos)
		_panel_rope.set_point_position(1, Vector2(panel_position.x, _panel.position.y - _panel.panel_size.y * 0.5))


## Jumping onto the button is the platformer equivalent of the stop-clock click:
## inside the 0.00 window it wins; landing on it too early fails "Too early!".
func _on_button_body_entered(body: Node) -> void:
	if _is_completed or _is_failed:
		return
	if not _button.input_pickable:  # panel still covers the button
		return
	if LevelTimer.has_timed_out():
		return
	if body is CharacterBody2D and (body.collision_layer & (1 << 0)):
		if LevelTimer.get_remaining() <= win_tolerance:
			_complete()
		else:
			_fail("Too early!")


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func get_progress_ratio() -> float:
	if _is_completed:
		return 1.0
	if _panel_raised or (is_instance_valid(_panel) and _panel.is_fully_raised()):
		if (not LevelTimer.has_timed_out()) and LevelTimer.get_remaining() <= win_tolerance:
			return 0.9  # in the 0.00 win window — click now!
		return 0.7
	if _platform.is_occupied():
		return 0.4
	return 0.0


func get_progress_text() -> String:
	if _is_completed:
		return "Complete!"
	var raised: bool = _panel_raised or (is_instance_valid(_panel) and _panel.is_fully_raised())
	if raised and (not LevelTimer.has_timed_out()) and LevelTimer.get_remaining() <= win_tolerance:
		return "Click the button now!"
	if raised:
		return "Panel raised - wait for 0.00, then click!"
	if _platform.is_occupied():
		return "Platform sinking..."
	return "Jump on the platform to raise the panel"