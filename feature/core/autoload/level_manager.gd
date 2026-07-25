extends Node
## Level registry + scene transitions + unlock/progress logic.
## Owns the "current level id" so any node (HUD, objectives, save logic)
## can query context without coupling.
##
## Level metadata is loaded from scenes/levels/levels.json at _ready().
## Edit that JSON file to add/reorder levels — no code changes needed.

const MAIN_MENU: String = "res://scenes/level_select.tscn"  # Use level select with thumbnails
const LEVELS_FILE: String = "res://scenes/levels/levels.json"

var _levels: Array = []

const AUTO_RELOAD_ON_FAIL_SEC: float = 1.2

var _current_level_id: String = ""
var _is_reloading_after_fail: bool = false


# ---------- Lifecycle ----------

func _ready() -> void:
	_load_levels_from_json()


# ---------- Queries ----------

func get_current_level_id() -> String:
	return _current_level_id


func get_level_ids() -> Array:
	var ids: Array = []
	for entry in _levels:
		ids.append(entry["id"])
	return ids


func get_level_path(level_id: String) -> String:
	var entry: Dictionary = _find_entry(level_id)
	return entry.get("path", "")


func get_level_metadata(level_id: String) -> Dictionary:
	return _find_entry(level_id).duplicate()


func get_level_index(level_id: String) -> int:
	for i in range(_levels.size()):
		if _levels[i]["id"] == level_id:
			return i
	return -1


func get_next_level_id() -> String:
	var idx: int = get_level_index(_current_level_id)
	if idx < 0 or idx + 1 >= _levels.size():
		return ""
	return _levels[idx + 1]["id"]


func is_level_unlocked(level_id: String) -> bool:
	var idx: int = get_level_index(level_id)
	if idx < 0:
		return false
	# All levels unlocked for testing
	return true
	# Original cascade logic (disabled for testing):
	# if idx == 0:
	# 	return true
	# var prev_id: String = _levels[idx - 1]["id"]
	# return SaveManager.is_level_completed(prev_id)


## Returns { "completed": int, "total": int, "ratio": float }
func get_progress() -> Dictionary:
	var completed: int = 0
	for entry in _levels:
		if SaveManager.is_level_completed(entry["id"]):
			completed += 1
	var total: int = _levels.size()
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


## Dev/F6 support: adopt the currently-running scene as the active level WITHOUT
## reloading it. Sets _current_level_id and starts the timer from levels.json so
## complete_current_level / fail_current_level work when running a level scene
## standalone via F6. No-op in normal play (load_level already set the context).
func begin_dev_test(level_id: String) -> void:
	if _current_level_id != "":
		return
	var entry: Dictionary = _find_entry(level_id)
	if entry.is_empty():
		push_warning("[LevelManager] dev-test: unknown level id '%s' (not in %s)" % [level_id, LEVELS_FILE])
		return
	_current_level_id = level_id
	var mode_str: String = entry.get("timer_mode", "count_up")
	var mode: int = LevelTimer.Mode.COUNT_DOWN if mode_str == "count_down" else LevelTimer.Mode.COUNT_UP
	var limit: float = float(entry.get("time_limit", 0.0))
	LevelTimer.start(level_id, mode, limit)


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
	# Per-level opt-out: some levels (e.g., Stop the Clock) don't record a time.
	var entry: Dictionary = _find_entry(_current_level_id)
	var record_time: bool = bool(entry.get("record_time", true))
	var is_new_best: bool = false
	if record_time:
		# Count-up: lower elapsed is better. Count-down: higher remaining is better.
		var lower_is_better: bool = not LevelTimer.is_countdown()
		is_new_best = SaveManager.set_best_time(_current_level_id, final_time, lower_is_better)
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
	for entry in _levels:
		if entry["id"] == level_id:
			return entry
	return {}


# ---------- Loading ----------

## Load level registry from scenes/levels/levels.json.
## Each entry supports: id (required), title, subtitle, timer_mode, time_limit,
## order, path. Missing fields use defaults; path defaults to
## "res://scenes/levels/<id>.tscn". Thumbnails are generated at runtime
## by level_select.gd via SubViewport, so no thumbnail_path field is needed.
func _load_levels_from_json() -> void:
	var file: FileAccess = FileAccess.open(LEVELS_FILE, FileAccess.READ)
	if file == null:
		push_error("[LevelManager] Cannot open levels file: %s" % LEVELS_FILE)
		return
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[LevelManager] Invalid JSON in %s (expected object with 'levels' array)" % LEVELS_FILE)
		return

	var root: Dictionary = parsed
	if not root.has("levels"):
		push_error("[LevelManager] JSON missing 'levels' array in %s" % LEVELS_FILE)
		return

	var arr: Array = root["levels"]
	var temp: Array = []
	for raw in arr:
		if typeof(raw) != TYPE_DICTIONARY:
			push_warning("[LevelManager] Skipping non-object level entry: %s" % str(raw))
			continue
		var entry: Dictionary = raw
		var id: String = entry.get("id", "")
		if id == "":
			push_warning("[LevelManager] Skipping level entry with no id: %s" % str(entry))
			continue
		var path: String = entry.get("path", "res://scenes/levels/%s.tscn" % id)
		var title: String = entry.get("title", "Untitled Level")
		var subtitle: String = entry.get("subtitle", "")
		var timer_mode: String = entry.get("timer_mode", "count_up")
		var time_limit: float = float(entry.get("time_limit", 0.0))
		var order: int = int(entry.get("order", 100))
		if title == "Untitled Level":
			push_warning("[LevelManager] Level '%s' uses default title — set it in %s" % [id, LEVELS_FILE])
		temp.append({
			"id": id,
			"path": path,
			"title": title,
			"subtitle": subtitle,
			"timer_mode": timer_mode,
			"time_limit": time_limit,
			"order": order,
		})

	# Sort by (order, id) ascending so designers control sequence via the `order` field.
	temp.sort_custom(func(a, b):
		if a["order"] != b["order"]:
			return a["order"] < b["order"]
		return a["id"] < b["id"])

	_levels = temp
	if _levels.is_empty():
		push_error("[LevelManager] No levels found in %s" % LEVELS_FILE)
