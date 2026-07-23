extends Node
## Per-level save data. Persists completion state and best times in user://.
## Uses ConfigFile for structured storage; .get(key, default) tolerates schema growth.

const SAVE_PATH: String = "user://save_data.cfg"
const SECTION_LEVELS: String = "levels"

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load()


func _load() -> void:
	var err: int = _config.load(SAVE_PATH)
	if err == ERR_FILE_NOT_FOUND:
		# Fresh save — nothing to load, not an error.
		return
	if err != OK:
		push_error("[SaveManager] Failed to load save file (err=%d)" % err)


func _persist() -> void:
	var err: int = _config.save(SAVE_PATH)
	if err != OK:
		push_error("[SaveManager] Failed to write save file (err=%d)" % err)
	else:
		SignalBus.save_written.emit()


func set_level_completed(level_id: String, completed: bool = true) -> void:
	_config.set_value(SECTION_LEVELS, "%s/completed" % level_id, completed)
	_persist()


func is_level_completed(level_id: String) -> bool:
	return bool(_config.get_value(SECTION_LEVELS, "%s/completed" % level_id, false))


## Returns true if `time_seconds` set a new best.
## `lower_is_better`: true for count-up (race-style), false for count-down
## (where the saved value is remaining time — higher is better).
## First record always wins.
func set_best_time(level_id: String, time_seconds: float, lower_is_better: bool = true) -> bool:
	var key: String = "%s/best_time" % level_id
	var has_record: bool = _config.has_section_key(SECTION_LEVELS, key)
	var is_better: bool
	if not has_record:
		is_better = true
	else:
		var current: float = float(_config.get_value(SECTION_LEVELS, key))
		is_better = (time_seconds < current) if lower_is_better else (time_seconds > current)
	if is_better:
		_config.set_value(SECTION_LEVELS, key, time_seconds)
		_persist()
		return true
	return false


func get_best_time(level_id: String) -> float:
	return float(_config.get_value(SECTION_LEVELS, "%s/best_time" % level_id, INF))


func reset_all() -> void:
	_config.clear()
	_persist()


## Remove all saved data for a single level (used by test scenes to clean up).
## Safe to call even when no save file or section exists yet.
func delete_level_data(level_id: String) -> void:
	var key_c: String = "%s/completed" % level_id
	var key_t: String = "%s/best_time" % level_id
	if _config.has_section_key(SECTION_LEVELS, key_c):
		_config.erase_section_key(SECTION_LEVELS, key_c)
	if _config.has_section_key(SECTION_LEVELS, key_t):
		_config.erase_section_key(SECTION_LEVELS, key_t)
	_persist()


## Returns true if any data exists for the given level.
func has_level_data(level_id: String) -> bool:
	return _config.has_section_key(SECTION_LEVELS, "%s/completed" % level_id) \
		or _config.has_section_key(SECTION_LEVELS, "%s/best_time" % level_id)
