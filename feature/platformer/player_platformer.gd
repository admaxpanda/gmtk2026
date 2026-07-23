class_name PlayerPlatformer
extends CharacterBody2D
## 2D platformer controller with professional feel:
##   - Gravity accumulates only when airborne (no floor jitter)
##   - Coyote time (~0.10s): can still jump shortly after leaving ledge
##   - Jump buffering (~0.15s): press jump slightly early, fires on landing
##   - Variable jump height: release early for shorter hops
##
## Expects Input actions: move_left, move_right, jump.

@export_group("Movement")
@export var move_speed: float = 240.0
@export var acceleration: float = 1800.0
@export var friction: float = 1600.0

@export_group("Jump")
@export var jump_velocity: float = -480.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.15
@export var variable_jump_factor: float = 0.5  # velocity scale on early release

@export_group("Gravity")
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 900.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_jump_held: bool = false


func _ready() -> void:
	collision_layer = 1 << 0  # player
	collision_mask = 1 << 1   # solid
	_build_visual()


func _build_visual() -> void:
	var rect := ColorRect.new()
	rect.name = "Visual"
	rect.size = Vector2(36, 52)
	rect.color = Color(0.35, 0.75, 0.95)
	rect.position = Vector2(-18, -26)
	add_child(rect)
	# Origin sits at the bottom-center so it aligns with the collision shape.
	var col := CollisionShape2D.new()
	col.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36, 52)
	col.shape = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal(delta)
	_handle_jump()
	move_and_slide()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		# Zero out residual downward velocity to avoid micro-jitter on floor snap.
		if velocity.y > 0.0:
			velocity.y = 0.0
		return
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)


func _handle_horizontal(delta: float) -> void:
	var dir: float = Input.get_axis(&"move_left", &"move_right")
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_jump() -> void:
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = jump_buffer_time
		_is_jump_held = true
	if Input.is_action_just_released(&"jump"):
		_is_jump_held = false
		# Variable jump: cut upward velocity when released early.
		if velocity.y < 0.0:
			velocity.y *= variable_jump_factor

	# Consume buffer if we have coyote time.
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0


# --- Read-only state for diagnostics / test scenes ---

func get_coyote_remaining() -> float:
	return _coyote_timer


func get_jump_buffer_remaining() -> float:
	return _jump_buffer_timer


func is_jump_held() -> bool:
	return _is_jump_held


func kill() -> void:
	# Called by hazard zones. LevelManager.fail_current_level already handles
	# the failure animation delay and auto-reload — do NOT reload here too,
	# otherwise reload_current() fires twice (once here, once in fail_current_level).
	LevelManager.fail_current_level("player_died")
