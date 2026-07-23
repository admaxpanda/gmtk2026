extends Node
## Universal, per-level independent timer. Supports two modes:
##   - COUNT_UP:   elapsed grows from 0 (race-style, lower is better)
##   - COUNT_DOWN: remaining shrinks from time_limit to 0 (limit-style)
##
## Uses Time.get_ticks_msec() (monotonic) for accuracy across pause/resume.
## Emits `tick(display_time)` every frame while running and `timed_out` once
## when a countdown reaches zero.

signal tick(display_time: float)
signal timed_out

enum Mode { COUNT_UP, COUNT_DOWN }

var _level_id: String = ""
var _mode: Mode = Mode.COUNT_UP
var _time_limit: float = 0.0
var _running: bool = false
var _start_msec: int = 0
var _accumulated: float = 0.0  # elapsed seconds accrued before current run segment
var _timed_out_fired: bool = false


func start(level_id: String, mode: Mode = Mode.COUNT_UP, time_limit: float = 0.0) -> void:
	_level_id = level_id
	_mode = mode
	_time_limit = max(time_limit, 0.0)
	_accumulated = 0.0
	_start_msec = Time.get_ticks_msec()
	_running = true
	_timed_out_fired = false


func stop() -> float:
	# Returns the final display time (remaining for countdown, elapsed for count-up).
	var final_time: float = get_display_time()
	# Freeze _accumulated at the current elapsed so post-stop queries stay
	# consistent with the returned final_time (mirrors the timeout freeze in
	# _process which sets _accumulated = _time_limit).
	_accumulated = get_elapsed()
	_running = false
	return final_time


func pause_timer() -> void:
	if _running:
		_accumulated = get_elapsed()
		_running = false


func resume_timer() -> void:
	if not _running and _level_id != "" and not _timed_out_fired:
		_start_msec = Time.get_ticks_msec()
		_running = true


func reset_timer() -> void:
	_running = false
	_accumulated = 0.0
	_start_msec = 0
	_timed_out_fired = false


# ---------- Queries ----------

## Raw elapsed seconds since start (always grows, regardless of mode).
func get_elapsed() -> float:
	if _running:
		return _accumulated + (Time.get_ticks_msec() - _start_msec) / 1000.0
	return _accumulated


## Remaining seconds for countdown mode. Returns 0 for count-up mode.
func get_remaining() -> float:
	if _mode != Mode.COUNT_DOWN:
		return 0.0
	return max(_time_limit - get_elapsed(), 0.0)


## The value HUDs should display: remaining for countdown, elapsed for count-up.
func get_display_time() -> float:
	if _mode == Mode.COUNT_DOWN:
		return get_remaining()
	return get_elapsed()


func get_mode() -> Mode:
	return _mode


func get_time_limit() -> float:
	return _time_limit


func get_current_level_id() -> String:
	return _level_id


func is_running() -> bool:
	return _running


func is_countdown() -> bool:
	return _mode == Mode.COUNT_DOWN


func has_timed_out() -> bool:
	return _timed_out_fired


func _process(_delta: float) -> void:
	if not _running:
		return
	tick.emit(get_display_time())
	# Countdown expiry check — fire once, then halt so the timer freezes at 0.
	if _mode == Mode.COUNT_DOWN and not _timed_out_fired:
		if get_elapsed() >= _time_limit:
			_accumulated = _time_limit
			_running = false
			_timed_out_fired = true
			tick.emit(0.0)
			timed_out.emit()
