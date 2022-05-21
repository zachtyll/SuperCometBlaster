class_name Comet
extends RigidBody2D
# General Comet class.

# TODO
# - Move comet spawn into it's own
#	node or nodes.


export(int) var score
export(PackedScene) var comet_child
export(int) var amount_children
# Imitate movement
puppet var puppet_transform setget puppet_transform_set
# Synching
var sync_spawn := 0
var sync_despawn := 0
var data_array := []
var enemy_data
remotesync var synced := false
## Physics
#var velocity := Vector2.ZERO
#var impulse := Vector2.ZERO
#var force := Vector2.ZERO # (UNUSED).

onready var stats : Node = $Stats
onready var tween := $Tween
onready var network := $TickRate
onready var comet_radius : int = $CollisionShape2D.shape.radius
onready var screen_size : Vector2 = get_viewport_rect().size
# Used to recognize who to assign score. (UNUSED)
onready var last_hit := ""

signal despawn
signal spawn

func puppet_transform_set(new_puppet_transform) -> void:
	if puppet_transform == new_puppet_transform:
		return
	puppet_transform = new_puppet_transform
	tween.interpolate_property(
		self, "global_transform", global_transform, puppet_transform, 0.001
		)
	tween.start()


func _integrate_forces(state):
	var xform = state.get_transform()
	if is_network_master() and is_instance_valid(self):
		xform.origin.x = wrapf(global_transform.origin.x, 0, screen_size.x)
		xform.origin.y = wrapf(global_transform.origin.y, 0, screen_size.y)
		state.set_transform(xform)
		
	elif not is_network_master() and is_instance_valid(self):
		if puppet_transform:
			global_transform = puppet_transform


func _on_Hurtbox_area_entered(area: Hitbox) -> void:
	if not is_network_master():
		return
	
	var hitbox := area as Hitbox
	if not hitbox:
		return
	else:
#		print(str(hitbox.get_parent().name) + " is attacking " + str(self.name))
		stats.health -= hitbox.damage

		var dest_vector = hitbox.get_global_transform().origin - get_global_transform().origin
		apply_impulse(Vector2.ZERO, -dest_vector * hitbox.knockback)


# NOTE : Only runs on master!
func _on_Stats_no_health() -> void:
	# This signal is sent to:
	# - Objective Manager
	self.emit_signal("despawn", self)
	pre_spawn_comet(amount_children)
	rpc("comet_death")
	# If singleplayer. (Quick dirty solution).
	if get_tree().get_network_connected_peers().size() == 0:
		despawn()


remote func comet_death() -> void:
	rpc_id(1, "notify_despawn")



remotesync func despawn() -> void:
	self.queue_free()


func pre_spawn_comet(amount : int) -> void:
	for _comet in range(amount):
		enemy_data = {
			"linear_velocity" : self.linear_velocity,
			"velocity" : Vector2.ZERO,
			"global_transform" : self.global_transform,
			"name" : "Comet_" + str(Gamestate.networked_object_name_index),
		}
		rpc("spawn_comet", enemy_data)
	

# TODO : Even cooler if we signal for death, then have "emitter-classes"
# For releasing all extra effects. This will most likely scale better too. 
remotesync func spawn_comet(comet : Dictionary) -> void:
	var enemy_death_list = self.get_signal_connection_list("spawn")
	var enemy_spawn_list = self.get_signal_connection_list("despawn")
	
	var enemy_instance = comet_child.instance()
	enemy_instance.name = comet.name
	
	match(enemy_instance.get_class()):
		"RigidBody2D":
			enemy_instance.linear_velocity = comet.linear_velocity
		"KinematicBody2D":
			enemy_instance.velocity = comet.velocity
		_:
			continue
	enemy_instance.global_transform = comet.global_transform
	
	var _err_enemy_death = enemy_instance.connect("despawn", enemy_death_list[0].target, "_on_enemy_death")
	var _err_enemy_spawn_manager = enemy_instance.connect("spawn", enemy_spawn_list[0].target, "_on_enemy_spawn")

	Gamestate.global_spawn(enemy_instance)


master func notify_spawn() -> void:
	sync_spawn += 1
	if sync_spawn == get_tree().get_network_connected_peers().size():
		rset("synced", true)
		if is_network_master():
			dirty_sync(0)


master func notify_despawn() -> void:
	sync_despawn += 1
	if sync_despawn == get_tree().get_network_connected_peers().size():
		network.stop()
		rpc("despawn")
		if is_network_master():
			dirty_sync(1)


func dirty_sync(type : int) -> void:
	match(type):
		0:
			sync_spawn = 0
		1:
			sync_despawn = 0
		_:
			push_error("Not a sync type.")


func _on_Tick_Rate_timeout():
	if is_network_master() and is_instance_valid(self):
		if synced:
			rset_unreliable("puppet_transform", global_transform)
		else:
#			print("NO SYNC with: %s" % self.name)
			pass


func _ready() -> void:
	self.set_network_master(1)
	if not is_network_master():
		rpc_id(1, "notify_spawn")
	emit_signal("spawn", self)
	network.start()
