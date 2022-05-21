extends Node2D
 

var synced_peers := 0
var data_array := []
var projectile_data

onready var projectile_scene : PackedScene = $WeaponStats.projectile
onready var fire_rate : float = $WeaponStats.fire_rate



master func fire_weapon() -> void:
	if $FireRate.is_stopped() and is_network_master():
		pre_spawn_projectile()
		$FireRate.start()
	else:
		return

# TODO : It is when the projectiles spawn that they cause
#	issues with the rpc. It must be because of call_deferred.
func pre_spawn_projectile() -> void:
	projectile_data = {
		"source" : self.owner.owner.name,
		"sync_name" : "Projectile_%s" % [str(Gamestate.networked_object_name_index)],
		"position" : $CastPoint.global_position,
		"rotation" : owner.rotation,
		"velocity" : owner.velocity,
		"impulse" : Vector2(0, -200),
	}
	
	data_array.append(projectile_data)
	rpc("remote_spawn_projectile", projectile_data)

	if get_tree().get_network_connected_peers().size() == 0:
		master_spawn_projectile(data_array)


remote func remote_spawn_projectile(projectile : Dictionary) -> void:
	spawn_projectile(projectile)


func master_spawn_projectile(data : Array) -> void:
	for projectile in data:
#		print("Master data: %s" % projectile)
		spawn_projectile(projectile)
		data_array.erase(projectile)


func spawn_projectile(projectile : Dictionary) -> void:
	var projectile_instance = projectile_scene.instance()
	projectile_instance.set_name(projectile.sync_name)
	projectile_instance.connect("ready", self, "_on_projectile_ready")
	projectile_instance.source = self.owner.owner.name
	projectile_instance.global_position = projectile.position
	projectile_instance.rotation = projectile.rotation
	projectile_instance.velocity = projectile.velocity
	projectile_instance.impulse = projectile.impulse
	self.add_child(projectile_instance)


func _on_projectile_ready() -> void:
	if not is_network_master():
		rpc_id(1, "indicate_sync")


master func indicate_sync() -> void:
	synced_peers += 1
	var number_of_peers = get_tree().get_network_connected_peers().size()
	if synced_peers == number_of_peers:
		master_spawn_projectile(data_array)
		if is_network_master():
			dirty_sync()


func dirty_sync() -> void:
	synced_peers = 0


func _on_Fire_Rate_timeout() -> void:
	$FireRate.stop()


func _ready() -> void:
	$FireRate.set_wait_time(fire_rate)
