class_name ReachGoalObjective
extends LevelObjective
## Win condition: any body on the player physics layer enters the goal area.
## Builds its own Area2D + visual + collider so the .tscn stays minimal.

@export var goal_position: Vector2 = Vector2(800, 400)
@export var goal_size: Vector2 = Vector2(80, 80)
@export var color: Color = Color(0.35, 0.85, 0.45, 0.65)
@export var label_text: String = "GOAL"

var _goal_area: Area2D


func _ready() -> void:
	_goal_area = Area2D.new()
	_goal_area.name = "GoalArea"
	_goal_area.position = goal_position
	_goal_area.collision_layer = 1 << 2  # goal
	_goal_area.collision_mask = 1 << 0   # detect player
	_goal_area.monitoring = true
	_goal_area.monitorable = false

	var rect := ColorRect.new()
	rect.size = goal_size
	rect.color = color
	rect.position = -goal_size * 0.5
	_goal_area.add_child(rect)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = goal_size
	lbl.position = -goal_size * 0.5
	_goal_area.add_child(lbl)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = goal_size
	col.shape = shape
	_goal_area.add_child(col)

	_goal_area.body_entered.connect(_on_body_entered)
	add_child(_goal_area)


func _on_body_entered(body: Node) -> void:
	# Player layer is bit 0 (value 1). CharacterBody2D check filters out
	# non-player bodies that happen to share the layer.
	if body is CharacterBody2D and (body.collision_layer & (1 << 0)):
		_complete()
