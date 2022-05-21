extends MarginContainer
# Controls the center banner of the HUD.

# TODO:
# NOTE: Activates from death of pawn due to
#	multiple signals sent when dying.
#	Reason: hurtbox not deactiveated.

onready var label = $CenterContainer/Message as Label
onready var text_animation = $CenterContainer/TextAnimation as AnimationPlayer
onready var message: String = ""

export(Array, Animation) var text_type


func _on_update_level_begin(level_number : int) -> void:
	var new_message := "Level " + str(level_number)
	rpc("update_label", 0, new_message)


func _on_update_level_cleared() -> void:
	var new_message := "Sector cleared!"
	rpc("update_label", 1, new_message)


# Signalled from Player_Controller.
func _on_player_death(player_name : String) -> void:
	var new_message := "Player " + player_name + " was destroyed!"
	rpc("update_label", 2, new_message)


func _set_label_text() -> void:
	if label != null:
		label.set_text(message)
	else:
		return


remotesync func update_label(new_text_type : int, new_message: String) -> void:
	message = new_message
	if label != null:
		if text_type[new_text_type].resource_name == text_animation.current_animation:
			print("Returning.")
			return
		elif not text_animation.is_playing():
			print("Playing.")
			text_animation.stop()
			text_animation.play(text_type[new_text_type].resource_name)
		elif text_animation.is_playing():
			print("Queueing.")
			text_animation.queue(text_type[new_text_type].resource_name)
		else:
			push_warning("Unkown state in Banner_UI!")
			return
	else:
		return
