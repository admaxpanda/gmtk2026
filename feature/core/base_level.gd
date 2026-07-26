class_name BaseLevel
extends Node2D
## Base class for level scenes. Auto-discovers the first LevelObjective child
## and bridges its signals to LevelManager + SignalBus. Subclasses override
## _build_level() to populate platforms/walls/etc.

@export var bg_color: Color = Color(0.10, 0.12, 0.18)
@export var bg_size: Vector2 = Vector2(1280, 720)

var _objective: LevelObjective

# --- Level audio ---
# ticktock: looping ambience that plays for the whole level, stopped on win/fail.
# ring: one-shot celebratory jingle, played for RING_DURATION_SEC on clear.
var TICKTOCK_STREAM: AudioStreamMP3 = preload("res://ingame/ticktock.mp3")
const RINGING_STREAM: AudioStreamMP3 = preload("res://ingame/ringing.mp3")
const RING_DURATION_SEC: float = 1.0

var _ticktock_player: AudioStreamPlayer
var _ring_player: AudioStreamPlayer


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
	# --- Level audio: ticktock ambience + clear jingle (applies to every level) ---
	_setup_level_audio()
	SignalBus.level_completed.connect(_on_audio_level_completed)
	SignalBus.level_failed.connect(_on_audio_level_failed)


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


# --- Level audio (ticktock ambience + clear jingle) ---

func _setup_level_audio() -> void:
	# Ticktock: looping background ambience for the whole level.
	_ticktock_player = AudioStreamPlayer.new()
	_ticktock_player.name = "TicktockPlayer"
	_ticktock_player.stream = TICKTOCK_STREAM
	_ticktock_player.bus = &"Master"
	# Loop at runtime so we don't have to reimport the asset with loop=true.
	if TICKTOCK_STREAM != null:
		TICKTOCK_STREAM.loop = true
	add_child(_ticktock_player)
	_ticktock_player.play()

	# Ring: one-shot celebratory jingle, triggered on level clear.
	_ring_player = AudioStreamPlayer.new()
	_ring_player.name = "RingPlayer"
	_ring_player.stream = RINGING_STREAM
	_ring_player.bus = &"Master"
	add_child(_ring_player)


func _on_audio_level_completed(_level_id: String, _time: float) -> void:
	_stop_ticktock()
	_play_ring()


func _on_audio_level_failed(_level_id: String, _reason: String) -> void:
	_stop_ticktock()


func _stop_ticktock() -> void:
	if is_instance_valid(_ticktock_player) and _ticktock_player.playing:
		_ticktock_player.stop()


func _play_ring() -> void:
	var player := _ring_player
	if not is_instance_valid(player):
		return
	player.stop()
	player.play()
	# Stop the jingle after RING_DURATION_SEC. The timer uses PROCESS_MODE_ALWAYS
	# so it still fires while the tree is paused on the completion screen, and it
	# is a child node so it's cleaned up automatically on scene change.
	var ring_timer := Timer.new()
	ring_timer.name = "RingStopTimer"
	ring_timer.wait_time = RING_DURATION_SEC
	ring_timer.one_shot = true
	ring_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	ring_timer.timeout.connect(_on_ring_timer_timeout.bind(player))
	add_child(ring_timer)
	ring_timer.start()


func _on_ring_timer_timeout(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()


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
