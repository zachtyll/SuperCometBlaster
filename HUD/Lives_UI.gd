extends Control

var health = 0 setget set_health
var max_health = 0 setget set_max_health

onready var label = $MarginContainer/Health

func set_health(value):
	health = value
	if label != null:
		label.text = "HP " + str(health)
		
func set_max_health(value):
	max_health = max(value, 1)
	
func _ready():
	self.max_health = PlayerStats.max_health
	self.health = PlayerStats.health
	PlayerStats.connect("health_changed", self, "set_health")
