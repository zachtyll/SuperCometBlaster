extends Node2D

onready var pawn := $Spaceship

var player_name: String = "" setget set_player_name

signal player_death

# Input event handler.
#func _input(_ev: InputEvent) -> void:
#	if is_network_master() and is_instance_valid(pawn):
#		if Input.is_action_pressed("shoot"):
#			pawn.weapon.rpc_id(1, "fire_weapon")
#		var rotation_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
#		var thrust_dir := -Input.get_action_strength("ui_up")
#		pawn.rpc_id(1, "call_steer", rotation_dir)
#		pawn.rpc_id(1, "call_thrust", thrust_dir)
#	else:
#		return


func set_player_name(new_name):
	player_name = new_name
	get_node("Spaceship/Label").set_text(player_name)


func _on_update_level_begin(_value):
	print("LEVEL BEGIN (IN PC)!")


func _on_update_level_cleared(_value):
	print("LEVEL CLEARED (IN PC)!")


func _on_Timer_timeout():
	set_process_input(true)
	pawn.rpc("pawn_respawn")


# TODO : Something is wrong with this one. It seems to mess up
#	online sync.
func _on_Spaceship_Rigid_pawn_death():
#	print("%s has died." % player_name)
	emit_signal("player_death", player_name)
	set_process_input(false)
	$Timer.start()


func _network_process(input: Dictionary) -> void:
	$Spaceship.thrust_dir = input.get("input_vector", Vector2.ZERO).y
	$Spaceship.rotation_dir = input.get("input_vector", Vector2.ZERO).x


func _get_local_input() -> Dictionary:
	var rotation_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var thrust_dir := -Input.get_action_strength("ui_up")
	
	var input := {}
	if not rotation_dir == 0 or not thrust_dir == 0:
		input["input_vector"] = Vector2(rotation_dir, thrust_dir)

	return input

