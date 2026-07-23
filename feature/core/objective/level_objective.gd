class_name LevelObjective
extends Node
## Base class for level completion conditions.
## Subclasses build their gameplay in _ready() and call _complete() / _fail()
## when the win/lose condition is met. BaseLevel listens to the signals and
## forwards them to LevelManager.
##
## Why a Node (not a Resource)? Objectives own scene children (Area2D zones,
## draggables, etc.) and need _ready/_physics_process, so they must live in
## the tree. One objective per level — add it as a child of the BaseLevel root.

signal completed
signal failed(reason: String)
signal progress_changed(ratio: float, text: String)

@export var objective_name: String = ""

var _is_completed: bool = false
var _is_failed: bool = false


func is_completed() -> bool:
	return _is_completed


func is_failed() -> bool:
	return _is_failed


## Override to report 0..1 progress for HUD display. Default: 0 until completed.
func get_progress_ratio() -> float:
	return 1.0 if _is_completed else 0.0


## Override to report a human-readable progress string ("3 / 5", "12.4s", etc.).
func get_progress_text() -> String:
	return ""


## Subclasses call this to declare victory. Idempotent — second call is a no-op.
func _complete() -> void:
	if _is_completed or _is_failed:
		return
	_is_completed = true
	progress_changed.emit(1.0, get_progress_text())
	completed.emit()


## Subclasses call this to declare failure. Idempotent. LevelManager handles reload.
func _fail(reason: String = "") -> void:
	if _is_completed or _is_failed:
		return
	_is_failed = true
	failed.emit(reason)


## Emit a progress update without changing completion state.
func _emit_progress() -> void:
	progress_changed.emit(get_progress_ratio(), get_progress_text())
