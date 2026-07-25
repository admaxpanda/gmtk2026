# Stop the Clock Level Spec

## Why
The project's countdown levels so far use the timer as a *deadline* ("reach the goal before 0"). There is no level that turns the countdown's sub-second precision into the *core gameplay mechanic* — a reaction/timing challenge where the player must stop the clock at a specific instant. This level fills that gap and showcases the 2-decimal countdown display as a playable element.

## What Changes
- **NEW** `StopClockObjective` (`feature/core/objective/stop_clock_objective.gd`) — extends `LevelObjective`; builds a red clickable button with an on-button countdown label (2 decimals); clicking within a configurable tolerance of a target remaining time wins, clicking too early fails, and the existing `timed_out` path handles "didn't click in time".
- **NEW** level `level_07_stop_the_clock` (`scenes/levels/level_07_stop_the_clock.gd` + `.tscn`) — extends `BaseLevel`, places the button at screen center.
- **MODIFIED** `scenes/levels/levels.json` — register the new level (`count_down`, `time_limit: 10.0`, `order: 70`).
- **MODIFIED** `ui/hud.gd` — add a control hint for the new level in `_hint_for()`.
- **MODIFIED** `README.md` — document the new level and objective.

No changes to `LevelTimer`, `LevelManager`, `SaveManager`, or `SignalBus` — the level fully reuses the existing countdown + save + signal-bridge infrastructure.

## Impact
- **Affected specs**: none (new standalone level + objective; no existing spec modified).
- **Affected code**:
  - NEW: `feature/core/objective/stop_clock_objective.gd`
  - NEW: `scenes/levels/level_07_stop_the_clock.gd`, `scenes/levels/level_07_stop_the_clock.tscn`
  - MODIFIED: `scenes/levels/levels.json`
  - MODIFIED: `ui/hud.gd`
  - MODIFIED: `README.md`
- **Design note (best-time semantics)**: This level reuses the countdown save convention ("higher remaining = better"). For a "stop at zero" level, lower remaining is arguably more skillful, but applying the existing convention consistently keeps the save system untouched. This is an acceptable trade-off for a test level and can be refined later with a per-level `best_direction` override if desired.

## ADDED Requirements

### Requirement: StopClockObjective
The system SHALL provide a `StopClockObjective` node (extends `LevelObjective`) that builds a clickable red button displaying the current countdown remaining time to 2 decimal places, and resolves win/fail based on the click timing relative to a target remaining time.

Configuration (defaults match the requested level):
- `@export var target_remaining: float = 0.0` — the remaining-time value to click at.
- `@export var tolerance: float = 0.25` — win window half-width (seconds).
- `@export var button_position: Vector2 = Vector2(640, 360)` — screen center.
- `@export var button_size: Vector2 = Vector2(220, 220)`.
- `@export var button_color: Color = Color(0.80, 0.18, 0.18)`.

#### Scenario: Click within tolerance wins
- **WHEN** the countdown is running and the player left-clicks the button while `abs(remaining - target_remaining) <= tolerance`
- **THEN** the objective calls `_complete()` and `BaseLevel` forwards completion to `LevelManager` (which stops the timer and records the remaining time).

#### Scenario: Click too early fails
- **WHEN** the player clicks while `abs(remaining - target_remaining) > tolerance`
- **THEN** the objective calls `_fail(reason)` with a message showing the stopped time (e.g., "Too early! Stopped at 3.42s — click within 0.25s of 0.00."), `BaseLevel` forwards failure, and `LevelManager` auto-reloads after 0.6s.

#### Scenario: Timer reaches zero without a valid click
- **WHEN** the countdown reaches 0.00 and no winning click has occurred
- **THEN** `LevelTimer.timed_out` fires; `BaseLevel._on_timer_timed_out` (default) fails the level with "Time's up!" because the objective is not yet completed; the level auto-reloads.

#### Scenario: On-button countdown label updates every frame
- **WHEN** the objective is active and `LevelTimer` emits `tick(display_time)`
- **THEN** the button's `Label` shows the remaining time formatted to 2 decimals (e.g., "7.34", "0.05", "10.00").

#### Scenario: Same-frame click at zero wins before timeout
- **WHEN** the player clicks in the same frame the timer would first cross zero
- **THEN** `Area2D.input_event` (processed before `_process`) resolves the click first; `remaining <= tolerance` → `_complete()`; the subsequent `timed_out` is ignored because `is_completed()` is true.

#### Scenario: Preview mode (thumbnail) is safe
- **WHEN** the level is loaded into a `SubViewport` for thumbnail capture
- **THEN** the objective builds its visuals in `_ready()` but triggers no game logic — `LevelTimer` is not started (no `tick`), and `process_mode=DISABLED` blocks input, so no win/fail can fire.

#### Scenario: Progress reporting
- **WHEN** the objective is active
- **THEN** `get_progress_text()` returns the current remaining time to 2 decimals (e.g., "0.42s left"), shown in the HUD objective label.

### Requirement: level_07_stop_the_clock
The system SHALL register a new level `level_07_stop_the_clock` in `levels.json` (count_down mode, 10.0s limit, order 70) that places a `StopClockObjective` (target=0.00s, tolerance=0.25s) at the screen center.

#### Scenario: Level is playable from level select
- **WHEN** the player completes `level_03_topdown` (the previous registered level) and selects the new level
- **THEN** the level loads with a 10s countdown and a red button at center showing the remaining time to 2 decimals; the HUD shows the control hint.

#### Scenario: Background does not eat clicks
- **WHEN** `BaseLevel._build_background()` creates the full-screen `ColorRect`
- **THEN** it uses `mouse_filter = IGNORE` (already the BaseLevel default) so the button's `Area2D.input_event` receives clicks.
