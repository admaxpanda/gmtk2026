class_name PulleyObjective
extends LevelObjective
## Level 5 objective: Pulley.
## - Player controls a platformer character
## - A panel covers the button, blocking access
## - Player jumps on a pulley platform to sink it, raising the panel
## - When panel is raised, player can jump onto the button to win
## - Must complete within countdown time limit

@export var player_start: Vector2 = Vector2(200, 888)
@export var platform_position: Vector2 = Vector2(600, 880)
@export var platform_sink_depth: float = 200.0
@export var panel_position: Vector2 = Vector2(950, 760)
@export var panel_size: Vector2 = Vector2(140, 280)  # SlidingPanel visual size
@export var panel_max_rise: float = 200.0
@export var button_position: Vector2 = Vector2(950, 880)
@export var button_radius: float = 50.0
@export var button_color: Color = Color(0.80, 0.18, 0.18)
@export var ground_y: float = 940.0
@export var pulley_top_y: float = 200.0  # Decorative pulley position

var _player: PlayerPlatformer
var _platform: PulleyPlatform
var _panel: SlidingPanel
var _button: Area2D
var _ground: StaticBody2D
var _walls: StaticBody2D
var _platform_rope: Line2D  # Dynamic rope from pulley to platform
var _panel_rope: Line2D    # Dynamic rope from pulley to panel
var _pulley_top_y: float = 200.0  # Y position of pulley wheel


func _ready() -> void:
	_build_ground()
	_build_walls()
	_build_pulley_visual()
	_build_panel()
	_build_platform()
	_build_button()
	_build_player()

	# F6 dev support
	if LevelManager.get_current_level_id() == "":
		var level_id := get_tree().current_scene.scene_file_path.get_file().get_basename()
		LevelManager.begin_dev_test(level_id)

	_emit_progress()


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
	# Decorative pulley: a circle at top with two lines down to platform and panel
	var pulley_pos := Vector2((platform_position.x + panel_position.x) * 0.5, pulley_top_y)
	_pulley_top_y = pulley_pos.y

	# Pulley wheel
	var wheel := Polygon2D.new()
	wheel.polygon = _make_circle(20, 24)
	wheel.color = Color(0.45, 0.45, 0.50)
	wheel.position = pulley_pos
	add_child(wheel)

	# Rope from pulley to platform (dynamic)
	_platform_rope = Line2D.new()
	_platform_rope.width = 3
	_platform_rope.default_color = Color(0.65, 0.55, 0.40)
	_platform_rope.add_point(Vector2(platform_position.x, pulley_pos.y))
	_platform_rope.add_point(Vector2(platform_position.x, platform_position.y))
	add_child(_platform_rope)

	# Rope from pulley to panel (dynamic)
	_panel_rope = Line2D.new()
	_panel_rope.width = 3
	_panel_rope.default_color = Color(0.65, 0.55, 0.40)
	_panel_rope.add_point(Vector2(panel_position.x, pulley_pos.y))
	_panel_rope.add_point(Vector2(panel_position.x, panel_position.y - panel_size.y * 0.5))
	add_child(_panel_rope)


func _build_panel() -> void:
	_panel = SlidingPanel.new()
	_panel.position = panel_position
	_panel.max_rise = panel_max_rise
	add_child(_panel)


func _build_platform() -> void:
	_platform = PulleyPlatform.new()
	_platform.position = platform_position
	_platform.sink_depth = platform_sink_depth
	_platform.moved.connect(_on_platform_moved)
	add_child(_platform)


func _build_button() -> void:
	_button = Area2D.new()
	_button.name = "ClickButton"
	_button.position = button_position
	_button.input_pickable = false
	_button.collision_layer = 1 << 2  # goal/button layer
	_button.collision_mask = 1 << 0  # detect player
	_button.monitoring = true
	_button.monitorable = false

	# Round button visual on the ground
	var circle := Polygon2D.new()
	circle.polygon = _make_circle(button_radius, 32)
	circle.color = button_color
	_button.add_child(circle)

	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = button_radius
	col.shape = shape
	_button.add_child(col)

	_button.body_entered.connect(_on_button_body_entered)
	add_child(_button)


func _build_player() -> void:
	_player = PlayerPlatformer.new()
	_player.position = player_start
	add_child(_player)


func _on_platform_moved(delta_y: float) -> void:
	# Panel moves opposite to platform
	_panel.on_platform_moved(delta_y)
	# Update rope visuals to follow platform and panel positions
	_platform_rope.set_point_position(1, Vector2(platform_position.x, _platform.position.y))
	_panel_rope.set_point_position(1, Vector2(panel_position.x, _panel.position.y - _panel.panel_size.y * 0.5))


func _on_button_body_entered(body: Node) -> void:
	if _is_completed or _is_failed:
		return
	if body is CharacterBody2D and (body.collision_layer & (1 << 0)):
		_complete()


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func get_progress_ratio() -> float:
	if _is_completed:
		return 1.0
	if _panel.is_fully_raised():
		return 0.7
	if _platform.is_occupied():
		return 0.4
	return 0.0


func get_progress_text() -> String:
	if _is_completed:
		return "Complete!"
	if _panel.is_fully_raised():
		return "Panel raised - jump to the button!"
	if _platform.is_occupied():
		return "Platform sinking..."
	return "Jump on the platform to raise the panel"