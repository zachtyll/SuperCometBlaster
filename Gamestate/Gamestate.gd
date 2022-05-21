extends Node


const world_scene := preload("res://World/World.tscn")
const player_scene = preload("res://Player/PlayerController.tscn")

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT := 10567

# Max number of players.
const MAX_PEERS := 4


var peer = null

# Name for my player. (UNUSED).
var player_name := "The Warrior"

# Names for remote players in id:name format.
var players := {}
var players_ready := []

# Spawning synchroniser.
var replicate := {}
var synced_peers := 0

# Naming for objects that get spawned for godot to keep track.
var networked_object_name_index = 0 setget networked_object_name_index_set, networked_object_name_index_get
puppet var puppet_networked_object_name_index = 0 setget puppet_networked_object_name_index_set

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree.
func _player_connected(id : int):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc_id(id, "register_player", player_name)
	# Just for good measure...
	if get_tree().is_network_server():
		SyncManager.add_peer(id)


# Callback from SceneTree.
func _player_disconnected(id : int):
	if has_node("/root/World"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		if get_tree().is_network_server():
			SyncManager.remove_peer(id)
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.

remote func register_player(new_player_name : String):
	var id = get_tree().get_rpc_sender_id()
	players[id] = new_player_name
	emit_signal("player_list_changed")


func unregister_player(id : int):
# warning-ignore:return_value_discarded
	players.erase(id)
	emit_signal("player_list_changed")


remotesync func leave_game():
	var id = get_tree().get_rpc_sender_id()
	unregister_player(id)
	if get_tree().is_network_server():
		players.clear()
	peer.close_connection()


# Could be remotesync
remote func pre_start_game(spawn_points : Dictionary):
	var world = world_scene.instance()
	get_tree().get_root().add_child(world)

	# Spawn players
	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).global_position
		var player = player_scene.instance()

		player.set_name("Player" + str(Gamestate.networked_object_name_index))
		player.set_network_master(p_id) #set unique id as master.
		player.global_position = spawn_pos

		# Use unique ID as node name.
		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
		else:
			# Otherwise set name from peer.
			player.set_player_name(players[p_id])

		world.get_node("Players").add_child(player)
	
		# Setup the Health_UI and Banner_UI
		var health_ui = world.get_node("HUD/HealthUI/" + str(spawn_points[p_id]))
		player.pawn.stats.connect("health_changed", health_ui, "set_health")
		player.pawn.stats.set_health(player.pawn.stats.health)
		health_ui.show()
		var banner_ui = world.get_node("HUD/CenterBanner/Center/BannerUI")
		player.connect("player_death", banner_ui, "_on_player_death")
		
	var _error_on_update_level_begin = world.get_node("LevelManager").connect(
		"update_level_begin",
		 world.get_node("HUD/CenterBanner/Center/BannerUI"),
		 "_on_update_level_begin"
		)
	var _error_on_update_level_cleared = world.get_node("LevelManager").connect(
		"update_level_cleared",
		 world.get_node("HUD/CenterBanner/Center/BannerUI"),
		 "_on_update_level_cleared"
		)
	var _error_on_update_score = world.get_node("ObjectiveManager").connect(
		"update_score",
		 world.get_node("HUD/Notch/ScoreUI"),
		 "_on_Objective_Manager_update_score"
	)


	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()


# Could be remotesync
remote func post_start_game():
	if get_tree().is_network_server():
		yield(get_tree().create_timer(2.0), "timeout")
		SyncManager.start()
	get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id : int):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name : String):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)


func join_game(ip : String, new_player_name : String):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	assert(get_tree().is_network_server())

	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points := {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points.
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)

	pre_start_game(spawn_points)


func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()
	
	# Reset SyncManager
	SyncManager.stop()
	SyncManager.clear_peers()


# TODO: Use semaphores to synchronize this stuff.
# Just move them from the comets and weapon classes.
func global_spawn(instance) -> void:
	get_node("/root/World/Enemies").call_deferred("add_child", instance)
#	replicate[instance.name] = instance
	
#	instance.connect("ready", self, "_on_comet_ready")
#
#
#func _on_comet_ready() -> void:
#	if not is_network_master():
#		rpc_id(1, "indicate_sync")
#
#
#master func indicate_sync() -> void:
#	synced_peers += 1
#	if synced_peers == get_tree().get_network_connected_peers().size():
#		global_spawn(replicate)
#		if is_network_master():
#			dirty_sync()
#
#
#func dirty_sync() -> void:
#	synced_peers = 0


#func _node_added(node) -> void:
#	if node is RigidBody2D:
#		var node_name = node.name
#		print(node_name)


#func _node_removed(node) -> void:
#	if node is RigidBody2D:
#		var node_name = node.name
#		var self_id = get_tree().get_network_unique_id()
#		print("%s just had %s removed." % [self_id, node_name])


func networked_object_name_index_get():
	networked_object_name_index += 1
	return networked_object_name_index


func puppet_networked_object_name_index_set(new_value : String):
	networked_object_name_index = new_value


func networked_object_name_index_set(new_value : String):
	networked_object_name_index = new_value
	
	if get_tree().is_network_server():
		rset("puppet_networked_object_name_index", networked_object_name_index)


func _ready():
	var _error_network_peer_connected := get_tree().connect("network_peer_connected", self, "_player_connected")
	var _error_network_peer_disconnected := get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	var _error_connected_to_server := get_tree().connect("connected_to_server", self, "_connected_ok")
	var _error_connection_failed := get_tree().connect("connection_failed", self, "_connected_fail")
	var _error_server_disconnected := get_tree().connect("server_disconnected", self, "_server_disconnected")
#	var _error_node_added = get_tree().connect("node_added", self, "_node_added")
#	var _error_node_removed = get_tree().connect("node_removed", self, "_node_removed")

	var _error_sync_started := SyncManager.connect("sync_started", self, "_on_SyncManager_sync_started")
	
