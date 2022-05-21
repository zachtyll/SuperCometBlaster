extends Node

export(int) onready var max_health : int
remotesync var health : int setget set_health

signal no_health
signal health_changed

func set_health(new_health : int) -> void:
# warning-ignore:narrowing_conversion
	health = clamp(new_health, 0, max_health)
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")


func _ready():
	set_health(max_health)
