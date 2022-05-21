extends Node

var level: int = 0 setget set_level, get_level
onready var spawn_point_comet := $SpawnPointComet

# Goes to UI
signal update_level_begin
# Goes to UI
signal update_level_cleared


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_network_master():
		increment_level()


func set_level(value: int) -> void:
	level = value


func get_level() -> int:
	return level


func increment_level() -> void:
	level += 1
	($Timer as Timer).start()


func _begin_new_level() -> void:
	emit_signal("update_level_begin", get_level())
	if is_network_master():
		spawn_point_comet.begin_new_level(get_level())


func _on_Objective_Manager_update_objective_completed() -> void:
	emit_signal("update_level_cleared")
	if is_network_master():
		increment_level()


#func _input(_ev: InputEvent) -> void:
#	if is_network_master():
#		if Input.is_action_pressed("new_level"):
#			increment_level()
#			print("increment_level to: " + str(get_level()))
