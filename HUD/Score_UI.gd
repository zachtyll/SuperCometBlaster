extends MarginContainer

onready var label = $CenterContainer/Score

remotesync func _update_score(new_score : int) -> void:
	if label != null:
		label.text = "Score: " + str(new_score)


func _on_Objective_Manager_update_score(new_score : int):
	if not is_network_master():
		return
	rpc("_update_score", new_score)
