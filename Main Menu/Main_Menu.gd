extends Control
# Main menu screen.

func _on_Singleplayer_pressed() -> void:
	var player_name = "You"
	Gamestate.host_game(player_name)
	Gamestate.begin_game()
	hide()


func _on_Multiplayer_pressed() -> void:
	var _error_change_scene_multiplayer = get_tree().change_scene("res://Lobby Menu/Lobby_Menu.tscn")
	hide()


func _on_Quit_pressed() -> void:
	get_tree().quit() 
