extends Node
## Level registry + scene transitions + unlock/progress logic.
## Owns the "current level id" so any node (HUD, objectives, save logic)
## can query context without coupling.
##
## Levels are stored in an ordered Array so we can derive unlock state
## (a level is unlocked when the previous one is completed) and totals.
## Each entry optionally carries timer config (mode + time_limit).

const MAIN_MENU: String = "res://scenes/main_menu.tscn"

## Ordered level registry. Index 0 is the first level.
## timer_mode: "count_up" (default) or "count_down". time_limit: seconds (count_down only).
const LEVELS: Array = [
	{
		"id": "level_01_drag",
		"path": "res://scenes/levels/level_01_drag.tscn",
		"title": "Level 1 — Drag & Drop",
		"subtitle": "Drag the boxes into the drop zone.",
		"timer_mode": "count_up",
		"time_limit": 0.0,
	},
	{
		"id": "level_02_platform",
		"path": "res://scenes/levels/level_02_platform.tscn",
		"title": "Level 2 — Platformer",
		"subtitle": "Reach the goal before the clock runs out.",
		"timer_mode": "count_down",
		"time_limit": 60.0,
	},
	{
		"id": "level_03_topdown",
		"path": "res://scenes/levels/level_03_topdown.tscn",
		"title": "Level 3 — Top-Down",
		"subtitle": "Escape the maze before time runs out.",
		"timer_mode": "count_down",
		"time_limit": 45.0,
	},
]

const AUTO_RELOAD_ON_FAIL_SEC: float = 0.6

var _current_level_id: String = ""
var _is_reloading_after_fail: bool = false


# ---------- Queries ----------

func get_current_level_id() -> String:
	return _current_level_id


func get_level_ids() -> Array:
	var ids: Array = []
	for entry in LEVELS:
		ids.append(entry["id"])
	return ids


func get_level_path(level_id: String) -> String:
	var entry: Dictionary = _find_entry(level_id)
	return entry.get("path", "")


func get_level_metadata(level_id: String) -> Dictionary:
	return _find_entry(level_id).duplicate()


func get_level_index(level_id: String) -> int:
	for i in range(LEVELS.size()):
		if LEVELS[i]["id"] == level_id:
			return i
	return -1


func get_next_level_id() -> String:
	var idx: int = get_level_index(_current_level_id)
	if idx < 0 or idx + 1 >= LEVELS.size():
		return ""
	return LEVELS[idx + 1]["id"]


func is_level_unlocked(level_id: String) -> bool:
	var idx: int = get_level_index(level_id)
	if idx < 0:
		return false
	if idx == 0:
		return true
	# Unlock cascade: previous level must be completed.
	var prev_id: String = LEVELS[idx - 1]["id"]
	return SaveManager.is_level_completed(prev_id)


## Returns { "completed": int, "total": int, "ratio": float }
func get_progress() -> Dictionary:
	var completed: int = 0
	for entry in LEVELS:
		if SaveManager.is_level_completed(entry["id"]):
			completed += 1
	var total: int = LEVELS.size()
	return {
		"completed": completed,
		"total": total,
		"ratio": float(completed) / float(total) if total > 0 else 0.0,
	}


# ---------- Transitions ----------

func load_level(level_id: String) -> void:
	var entry: Dictionary = _find_entry(level_id)
	if not entry.has("path"):
		push_error("[LevelManager] Unknown level id: %s" % level_id)
		return
	if not is_level_unlocked(level_id):
		push_warning("[LevelManager] Level '%s' is locked." % level_id)
		return
	_current_level_id = level_id
	# Resolve timer config (defaults to count-up, no limit).
	var mode_str: String = entry.get("timer_mode", "count_up")
	var mode: int = LevelTimer.Mode.COUNT_DOWN if mode_str == "count_down" else LevelTimer.Mode.COUNT_UP
	var limit: float = float(entry.get("time_limit", 0.0))
	LevelTimer.start(level_id, mode, limit)
	SignalBus.level_started.emit(level_id)
	get_tree().change_scene_to_file(entry["path"])


func reload_current() -> void:
	if _current_level_id != "":
		# Re-read timer config so a retry restarts with the full countdown.
		var entry: Dictionary = _find_entry(_current_level_id)
		var mode_str: String = entry.get("timer_mode", "count_up")
		var mode: int = LevelTimer.Mode.COUNT_DOWN if mode_str == "count_down" else LevelTimer.Mode.COUNT_UP
		var limit: float = float(entry.get("time_limit", 0.0))
		LevelTimer.start(_current_level_id, mode, limit)
		SignalBus.level_started.emit(_current_level_id)
		get_tree().change_scene_to_file(entry["path"])


func go_to_menu() -> void:
	_current_level_id = ""
	LevelTimer.stop()
	get_tree().change_scene_to_file(MAIN_MENU)


## Advance to the next level. Falls back to menu if there isn't one.
func load_next_level() -> void:
	var next_id := get_next_level_id()
	if next_id == "":
		go_to_menu()
	else:
		load_level(next_id)


# ---------- Completion / Failure ----------

## Called by objectives / BaseLevel. Finalizes timer, writes save, emits signal.
## For countdown levels, the recorded "time" is the remaining time (higher = better).
func complete_current_level() -> void:
	if _current_level_id == "":
		push_warning("[LevelManager] complete_current_level called with no active level.")
		return
	var final_time: float = LevelTimer.stop()
	# Count-up: lower elapsed is better. Count-down: higher remaining is better.
	var lower_is_better: bool = not LevelTimer.is_countdown()
	var is_new_best: bool = SaveManager.set_best_time(_current_level_id, final_time, lower_is_better)
	SaveManager.set_level_completed(_current_level_id, true)
	SignalBus.level_completed.emit(_current_level_id, final_time)
	print("[LevelManager] Level '%s' completed (time=%0.3fs, new best=%s)" % [_current_level_id, final_time, is_new_best])


## Called by objectives on failure. Pauses the timer and schedules an auto-reload
## so the player gets a brief beat to register what happened.
func fail_current_level(reason: String = "") -> void:
	if _current_level_id == "":
		return
	if _is_reloading_after_fail:
		return
	_is_reloading_after_fail = true
	var failed_id: String = _current_level_id
	LevelTimer.pause_timer()
	SignalBus.level_failed.emit(_current_level_id, reason)
	print("[LevelManager] Level '%s' failed: %s" % [_current_level_id, reason])
	# Defer the reload so the failure signal can be observed (HUD flash, VFX, etc.)
	await get_tree().create_timer(AUTO_RELOAD_ON_FAIL_SEC).timeout
	_is_reloading_after_fail = false
	# Only reload if we're still on the same failed level — the player may have
	# returned to the menu or started a different level during the delay window.
	if _current_level_id == failed_id and is_instance_valid(get_tree()):
		reload_current()


# ---------- Internals ----------

func _find_entry(level_id: String) -> Dictionary:
	for entry in LEVELS:
		if entry["id"] == level_id:
			return entry
	return {}
