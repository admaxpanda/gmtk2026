class_name Level03ClearPath
extends BaseLevel
## Level 3 — Clear Path.
## A blue paper block covers the button. Drag it to the trash bin
## to reveal the button, then click to complete.


func _ready() -> void:
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := ClearPathObjective.new()
	add_child(objective)