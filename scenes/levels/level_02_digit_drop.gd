class_name Level02DigitDrop
extends BaseLevel
## Level 2 — Digit Drop.
## A virtual timer shows high digits (1111), main timer shows units digit (0).
## Total time: 11110 seconds. Player can drag virtual timer to trash bin
## to truncate time to just the units digit, or wait for the countdown.
## Win condition: click the button when units digit is 0.


func _ready() -> void:
	bg_size = Vector2(1920, 1080)
	super._ready()


func _build_level() -> void:
	var objective := DigitDropObjective.new()
	add_child(objective)