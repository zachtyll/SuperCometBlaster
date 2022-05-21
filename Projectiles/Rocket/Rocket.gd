extends Projectile
# Rocket projectile, meant to be used with generic Projectile scene.


export(PackedScene) var explosion

#	This func must be remotesync since the projectile must dissapear
#	on all devices.
func _extra_effect() -> void:
	if not is_network_master():
		return
	_pre_spawn_explosion()


func _pre_spawn_explosion() -> void:
	var explosion_data := {
		"global_xform" : self.get_global_transform(),
		"name" : "Explosion_" + str(Gamestate.networked_object_name_index),
	}
	rpc("_spawn_explosion", explosion_data)


remotesync func _spawn_explosion(enemy_data : Dictionary) -> void:
	var explosion_instance = explosion.instance()
	# Must set as toplevel here, otherwise Area2D breaks.
	explosion_instance.set_as_toplevel(true)
	explosion_instance.name = enemy_data.name
	explosion_instance.global_transform = enemy_data.global_xform
	self.get_parent().call_deferred("add_child", explosion_instance)
	
#	rpc("_spawn_master_explosion", enemy_data)

#master func _spawn_master_explosion(enemy_data : Dictionary) -> void:
#	var explosion_instance = explosion.instance()
#	# Must set as toplevel here, otherwise Area2D breaks.
#	explosion_instance.set_as_toplevel(true)
#	explosion_instance.name = enemy_data.name
#	explosion_instance.global_transform = enemy_data.global_xform
#	self.get_parent().call_deferred("add_child", explosion_instance)
