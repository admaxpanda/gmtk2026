# Tasks

- [x] Task 1: Create `StopClockObjective` class
  - [ ] SubTask 1.1: Create `feature/core/objective/stop_clock_objective.gd` extending `LevelObjective`; add `@export` fields (`target_remaining=0.0`, `tolerance=0.25`, `button_position`, `button_size`, `button_color`).
  - [ ] SubTask 1.2: In `_ready()`, build an `Area2D` button (layer 3 / draggable-style, `input_pickable=true`) + red `ColorRect` visual + `CollisionShape2D` (RectangleShape2D) + a centered `Label` for the countdown text.
  - [ ] SubTask 1.3: Connect `LevelTimer.tick` to update the label to 2 decimals (`"%.2f" % display_time`); set an initial label in `_ready()` so it isn't blank before the first tick.
  - [ ] SubTask 1.4: Connect `Area2D.input_event`; on left-click press, read `LevelTimer.get_remaining()`, compute `error = abs(remaining - target_remaining)`; if `error <= tolerance` → `_complete()`, else → `_fail("Stopped at %.2fs — click within %.2fs of %.2f." % [remaining, tolerance, target_remaining])`.
  - [ ] SubTask 1.5: Override `get_progress_text()` to return `"%.2fs left" % LevelTimer.get_remaining()` (guard for non-countdown / preview).
- [x] Task 2: Create `level_07_stop_the_clock` scene + script
  - [ ] SubTask 2.1: Create `scenes/levels/level_07_stop_the_clock.gd` extending `BaseLevel`; in `_build_level()` create a `StopClockObjective` (default target=0.0, tolerance=0.25) and `add_child()` it.
  - [ ] SubTask 2.2: Create `scenes/levels/level_07_stop_the_clock.tscn` — minimal root `Node2D` with the script attached (mirror `level_02_platform.tscn` structure).
- [x] Task 3: Register level in `levels.json`
  - [ ] SubTask 3.1: Append entry: `id=level_07_stop_the_clock`, `title="Level 7 — Stop the Clock"`, `subtitle="Click the button when the countdown hits 0.00 (within 0.25s)."`, `timer_mode="count_down"`, `time_limit=10.0`, `order=70`.
- [x] Task 4: Add HUD hint
  - [ ] SubTask 4.1: Add a `level_07_stop_the_clock` case to `hud.gd` `_hint_for()` returning: `"Stop the Clock: Click the red button when the countdown hits 0.00 (within 0.25s).   |   Esc: Pause   R: Reset"`.
- [x] Task 5: Verify (parse check + code review)
  - [ ] SubTask 5.1: Run Godot headless import / `--check-only` to confirm no parse errors across new/modified scripts.
  - [ ] SubTask 5.2: Code review (subagent) for correctness vs. spec + project conventions (mouse_filter, idempotent complete/fail, preview-mode safety, signal-up architecture).
- [x] Task 6: Update README + commit + push
  - [x] SubTask 6.1: Document the new level and the `StopClockObjective` in `README.md` (levels table, objectives list, test/level section).
  - [x] SubTask 6.2: `git add` the new/modified files, commit with a descriptive message, and push to the remote repository. (Committed as 4d89d0d, rebased onto remote 2a60f82, pushed to origin/main. Only the 8 spec files were committed; user WIP left uncommitted per user choice.)

# Task Dependencies
- Task 2 depends on Task 1 (level script references the objective class).
- Tasks 3 and 4 are independent of Task 2 and may be done in parallel.
- Task 5 depends on Tasks 1–4.
- Task 6 depends on Task 5.
