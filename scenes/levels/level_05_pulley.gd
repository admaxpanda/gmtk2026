class_name Level05Pulley
extends BaseLevel
## Level 5 — Pulley.
## Player controls a platformer character. A panel covers the button.
## Jump on the pulley platform to sink it, raising the panel via the rope.
## When the panel is raised, jump onto the button to complete the level.


func _ready() -> void:
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := PulleyObjective.new()
	add_child(objective)