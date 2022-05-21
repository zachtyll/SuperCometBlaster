extends Node

var enemy_array = []
var enemy_count = 0 setget set_enemy_count, get_enemy_count
var score := 0

export(NodePath) onready var enemies = get_node(enemies) as Node2D

# This signal is received by:
	# - Score_UI
signal update_score
# This signal is received by:
#	- Level_Manager
signal update_objective_completed


func set_enemy_count(value: int) -> void:
	enemy_count = value


func get_enemy_count() -> int:
	return enemy_count


func is_objective_completed() -> bool:
	if get_enemy_count() == 0:
		return true
	else:
		return false


remotesync func _update_score(new_score : int) -> void:
	score += new_score
	emit_signal("update_score", score)


func _on_enemy_spawn(value) -> void:
	if not is_network_master():
		return
	enemy_array.append(value)
	set_enemy_count(enemy_array.size())


func _on_enemy_death(enemy) -> void:
	if not is_network_master():
		return
	_update_score(enemy.score)
	enemy_array.erase(enemy)
	set_enemy_count(enemy_array.size())
	if get_enemy_count() == 0:
		$Timer.start()
	else:
		pass


func _level_clear_delay():
	if is_objective_completed():
		emit_signal("update_objective_completed")
