extends Node
## Global signal bus. Strict limit of < 15 events to prevent debug sprawl.
## Signals flow UP from features; logic never reaches down through here.

signal level_started(level_id: String)
signal level_completed(level_id: String, time_seconds: float)
signal level_failed(level_id: String, reason: String)
signal timer_tick(elapsed_seconds: float)
signal objective_progress(ratio: float, text: String)
signal save_written
