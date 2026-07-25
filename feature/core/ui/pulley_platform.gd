class_name PulleyPlatform
extends AnimatableBody2D
## Platform that sinks when the player stands on it, linked to a sliding panel
## via a pulley. When platform sinks by N pixels, the linked panel rises by N.
##
## Behavior:
## - Detects player standing on top (Area2D sensor)
## - Sinks smoothly toward sink_depth when occupied
## - Rises back to original position when player leaves
## - Emits moved signal with delta so the linked panel can move opposite

signal moved(delta_y: float)  # Emit each frame the platform moves

@export var sink_depth: float = 200.0
@export var move_speed: float = 200.0  # pixels per second
@export var platform_size: Vector2 = Vector2(180, 24)
@export var platform_color: Color = Color(0.55, 0.55, 0.60)

var _original_position: Vector2 = Vector2.ZERO
var _is_occupied: bool = false
var _current_offset: float = 0.0  # 0 = top, sink_depth = bottom
var _visual: ColorRect
var _sensor: Area2D


func _ready() -> void:
	_original_position = position
	collision_layer = 1 << 1  # solid (player collides)
	collision_mask = 0

	_build_visual()
	_build_sensor()


func _build_visual() -> void:
	_visual = ColorRect.new()
	_visual.name = "Visual"
	_visual.size = platform_size
	_visual.color = platform_color
	_visual.position = -platform_size * 0.5
	add_child(_visual)

	var col := CollisionShape2D.new()
	col.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	col.shape = shape
	add_child(col)


func _build_sensor() -> void:
	# Sensor area above the platform to detect when player stands on top
	_sensor = Area2D.new()
	_sensor.name = "Sensor"
	_sensor.position = Vector2(0, -platform_size.y * 0.5 - 10)
	_sensor.collision_layer = 0
	_sensor.collision_mask = 1 << 0  # detect player
	_sensor.monitoring = true
	_sensor.monitorable = false

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(platform_size.x, 20)
	col.shape = shape
	_sensor.add_child(col)

	_sensor.body_entered.connect(_on_body_entered)
	_sensor.body_exited.connect(_on_body_exited)
	add_child(_sensor)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and (body.collision_layer & (1 << 0)):
		_is_occupied = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and (body.collision_layer & (1 << 0)):
		_is_occupied = false


func _physics_process(delta: float) -> void:
	# Safety: reset occupied state if player died or level changed
	if _is_occupied and not _is_valid_player_present():
		_is_occupied = false

	var target: float = sink_depth if _is_occupied else 0.0
	var prev_offset: float = _current_offset
	_current_offset = move_toward(_current_offset, target, move_speed * delta)
	var delta_y: float = _current_offset - prev_offset
	if delta_y != 0.0:
		position.y = _original_position.y + _current_offset
		moved.emit(delta_y)


func _is_valid_player_present() -> bool:
	# Check if player is still in the sensor area
	var bodies: Array[Node2D] = _sensor.get_overlapping_bodies()
	for body in bodies:
		if body is CharacterBody2D and (body.collision_layer & (1 << 0)):
			if is_instance_valid(body):
				return true
	return false


func is_occupied() -> bool:
	return _is_occupied


func get_offset() -> float:
	return _current_offset


func is_fully_sunk() -> bool:
	return _current_offset >= sink_depth - 1.0