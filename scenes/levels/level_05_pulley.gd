class_name Level05Pulley
extends BaseLevel
## Level 5 — Pulley.
## Player controls a platformer character. A panel covers the button.
## Jump on the pulley platform to sink it, raising the panel via the rope.
## Once the panel is raised, the button can be clicked — and the level only
## completes if the player clicks it within the 0.00 win window. Reaching
## 0.00 without a winning click FAILS the level (BaseLevel default).


func _ready() -> void:
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := PulleyObjective.new()
	add_child(objective)