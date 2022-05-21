extends RigidBody2D

enum CometSize {LARGE, MEDIUM, SMALL}
export(int) var score
export(CometSize) var comet_size

puppet var puppet_transform: Transform2D = Transform2D(rotation, position) setget puppet_transform_set

onready var stats = $Stats
onready var comet_radius = $CollisionShape2D.shape.extents
onready var screen_size = get_viewport_rect().size

func puppet_transform_set(value) -> void:
	puppet_transform = value


func _integrate_forces(state):
	if not is_network_master() and is_instance_valid(self):
		state.set_transform(puppet_transform)
	
	var xform = state.get_transform()
	xform.origin.x = wrapf(xform.origin.x, -comet_radius.x/2, screen_size.x + comet_radius.x/2)
	xform.origin.y = wrapf(xform.origin.y, -comet_radius.y/2, screen_size.y + comet_radius.y/2)
	state.set_transform(xform)


remotesync func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	if stats.health <= 0:
		if get_tree().is_network_server():
			rpc("pickup_taken")


remotesync func pickup_taken():
	queue_free()


func _on_Network_Tick_Rate_timeout():
	if is_network_master() and is_instance_valid(self):
		rset_unreliable("puppet_transform", global_transform)


func _on_Stats_no_health():
	pass # Replace with function body.
