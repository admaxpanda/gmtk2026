class_name PlayerTopDown
extends CharacterBody2D
## 2D top-down controller. 8-directional movement, no gravity.
## Uses acceleration/friction for a snappy-but-smooth feel.

@export var move_speed: float = 260.0
@export var acceleration: float = 2000.0
@export var friction: float = 2000.0

func _ready() -> void:
	collision_layer = 1 << 0  # player
	collision_mask = 1 << 1   # solid
	_build_visual()


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.name = "Visual"
	rect.size = Vector2(40, 40)
	rect.color = Color(0.55, 0.85, 0.45)
	rect.position = Vector2(-20, -20)
	add_child(rect)
	var col := CollisionShape2D.new()
	col.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	col.shape = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	var input_vec := Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down")
	)
	# Normalize diagonals so corner-to-corner isn't 1.41x faster.
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	if input_vec != Vector2.ZERO:
		velocity = velocity.move_toward(input_vec * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
