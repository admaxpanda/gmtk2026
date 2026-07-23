class_name BaseLevel
extends Node2D
## Base class for level scenes. Auto-discovers the first LevelObjective child
## and bridges its signals to LevelManager + SignalBus. Subclasses override
## _build_level() to populate platforms/walls/etc.

@export var bg_color: Color = Color(0.10, 0.12, 0.18)
@export var bg_size: Vector2 = Vector2(1280, 720)

var _objective: LevelObjective


func _ready() -> void:
	_build_background()
	_build_level()
	# Subclasses add the LevelObjective inside _build_level(), so discover it after.
	_objective = _find_objective()
	if _objective == null:
		push_warning("[%s] No LevelObjective child found — level cannot complete." % name)
	else:
		_objective.completed.connect(_on_objective_completed)
		_objective.failed.connect(_on_objective_failed)
		_objective.progress_changed.connect(_on_objective_progress)
	# Countdown expiry → default failure. Override _on_timer_timed_out for
	# "survive the timer" win conditions.
	LevelTimer.timed_out.connect(_on_timer_timed_out)


func _find_objective() -> LevelObjective:
	for child in get_children():
		if child is LevelObjective:
			return child
	return null


func get_objective() -> LevelObjective:
	return _objective


# --- Hooks for subclasses ---

func _build_background() -> void:
	# Default: ColorRect with top-left at the level root origin.
	# Levels whose root sits at (0,0) get a viewport-sized bg covering 0..1280, 0..720.
	var bg := ColorRect.new()
	bg.color = bg_color
	bg.size = bg_size
	bg.position = Vector2.ZERO
	# MUST ignore mouse events — otherwise this full-screen ColorRect eats every
	# click before Area2D.input_event (Draggable, ReachGoalObjective) can fire.
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_level() -> void:
	# Override in subclasses.
	pass


# --- Signal bridges ---

func _on_objective_completed() -> void:
	LevelManager.complete_current_level()


func _on_objective_failed(reason: String) -> void:
	LevelManager.fail_current_level(reason)


func _on_objective_progress(ratio: float, text: String) -> void:
	SignalBus.objective_progress.emit(ratio, text)


## Called when a countdown timer reaches zero. Default behavior: fail the level
## unless the objective has already been completed. Override in subclasses to
## implement "survive the timer" win conditions (call _objective._complete()).
func _on_timer_timed_out() -> void:
	if _objective != null and not _objective.is_completed():
		_on_objective_failed("Time's up!")


# --- Helper for subclasses: build a solid static rectangle (floor/wall/platform) ---

func build_solid(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
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

	add_child(body)
	return body
