extends BaseLevel
## Level 01 — Drag & Drop demo.
## Uses DragAllToZoneObjective: drag N boxes into the drop zone to win.

func _build_level() -> void:
	var objective := DragAllToZoneObjective.new()
	objective.zone_position = Vector2(900, 360)
	objective.zone_size = Vector2(420, 420)
	objective.required_count = 4
	objective.spawn_anchor = Vector2(180, 220)
	objective.spawn_step = Vector2(120, 140)
	add_child(objective)
