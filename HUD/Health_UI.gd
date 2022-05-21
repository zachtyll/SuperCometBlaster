extends MarginContainer
# Displays HP to player. Is signalled by Player.pawn.stats.

var player_labels = {}
var health: int = 0 setget set_health
var max_health: int = 0 setget set_max_health

onready var label = $Health as Label


func set_health(value: int) -> void:
	health = value
	if label != null:
		label.text = "HP: " + str(health)


func set_max_health(value: int) -> void:
# warning-ignore:narrowing_conversion
	max_health = max(value, 1)
