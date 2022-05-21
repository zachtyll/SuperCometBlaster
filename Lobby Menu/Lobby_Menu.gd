extends Control

onready var address := $ConnectionScreen/Panel/VBoxContainer/Address 
onready var player_username := $ConnectionScreen/Panel/VBoxContainer/Name
onready var host_button := $ConnectionScreen/Panel/VBoxContainer/ButtonBox/ButtonHost
onready var join_button := $ConnectionScreen/Panel/VBoxContainer/ButtonBox/ButtonJoin
onready var start_button := $LobbyScreen/Panel/VBoxContainer/HBoxContainer/Button_Start
onready var leave_button := $LobbyScreen/Panel/VBoxContainer/HBoxContainer/Button_Leave
onready var status := $ConnectionScreen/Panel/VBoxContainer/StatusBox/Status
onready var player_list := $LobbyScreen/Panel/VBoxContainer/PlayerList
onready var error_dialog := $ErrorDialog
onready var status_animation := $ConnectionScreen/Panel/VBoxContainer/StatusBox/AnimationStatus




func _on_Button_Host_pressed():
	if player_username.text == "":
		_set_status("Invalid name!", "Status_Regular")
		return

	($ConnectionScreen as MarginContainer).hide()
	($LobbyScreen as MarginContainer).show()
	_set_status("", "Status_Regular")

	var player_name = player_username.text
	Gamestate.host_game(player_name)
	refresh_lobby()
	_set_status("Waiting for player...", "Status_Regular")


func _on_Button_Join_pressed() -> void:
	if player_username.text == "":
		_set_status("Invalid name!", "Status_Regular")
		return

	var ip = address.text
	if not ip.is_valid_ip_address():
		_set_status("Invalid IP address!", "Status_Regular")
		return

	_set_status("", "Status_Regular")
	host_button.disabled = true
	join_button.disabled = true

	var player_name = player_username.text
	Gamestate.join_game(ip, player_name)

	_set_status("Connecting...", "Status_Wait")

func _on_connection_success() -> void:
	($ConnectionScreen as MarginContainer).hide()
	($LobbyScreen as MarginContainer).show()


func _on_connection_failed() -> void:
	host_button.disabled = false
	join_button.disabled = false
	_set_status("Connection failed.", "Status_Regular")


func _on_game_ended() -> void:
	show()
	($ConnectionScreen as MarginContainer).show()
	($LobbyScreen as MarginContainer).hide()
	host_button.disabled = false
	join_button.disabled = false


func _set_status(text: String, animation: String) -> void:
	status.set_text(text)
	status_animation.play(animation)


func _on_game_error(errtxt):
	error_dialog.dialog_text = errtxt
	error_dialog.popup_centered_minsize()
	host_button.disabled = false
	join_button.disabled = false


func refresh_lobby() -> void:
	var players = Gamestate.get_player_list()
	players.sort()
	player_list.clear()
	player_list.add_item(Gamestate.get_player_name() + " (You)")
	for p in players:
		player_list.add_item(p)

	start_button.disabled = not get_tree().is_network_server()


func _on_Button_Start_pressed():
	Gamestate.begin_game()
	($LobbyScreen as MarginContainer).hide()


func _on_Button_Leave_pressed():
	Gamestate.leave_game()
	($ConnectionScreen as MarginContainer).show()
	($LobbyScreen as MarginContainer).hide()
	host_button.disabled = false
	join_button.disabled = false
	
	_set_status("", "Status_Regular")


func _on_join_timeout():
	_set_status("Attempt timed out!", "Status_Regular")
	host_button.disabled = false
	join_button.disabled = false


func _ready() -> void:
	# Connect all the callbacks related to networking.
	var _error_connection_failed = Gamestate.connect("connection_failed", self, "_on_connection_failed")
	var _error_connection_succeeded = Gamestate.connect("connection_succeeded", self, "_on_connection_success")
	var _error_player_list_changed = Gamestate.connect("player_list_changed", self, "refresh_lobby")
	var _error_game_ended = Gamestate.connect("game_ended", self, "_on_game_ended")
	var _error_game_error = Gamestate.connect("game_error", self, "_on_game_error")


func _on_Back_pressed():
	var _error_change_scene_multiplayer = get_tree().change_scene("res://Main Menu/Main Menu.tscn")
	hide()
	
