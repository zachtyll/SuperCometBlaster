class_name Projectile
extends KinematicBody2D

puppet var puppet_position setget puppet_position_set
puppet var puppet_rotation setget puppet_rotation_set

var velocity := Vector2.ZERO
var impulse := Vector2.ZERO

onready var lifetime : Timer = $Lifetime as Timer
onready var tween := $Tween
onready var screen_size : Vector2 = get_viewport_rect().size as Vector2
onready var source = null

# warning-ignore:unused_signal
signal spawn
# warning-ignore:unused_signal
signal despawn

func puppet_rotation_set(new_puppet_rot) -> void:
	if puppet_rotation == new_puppet_rot:
		return
	puppet_rotation = new_puppet_rot
	tween.interpolate_property(
		self, "rotation", rotation, puppet_rotation, 0.001
		)
	tween.start()


# Tweens to the newly set global position from the old position.
func puppet_position_set(new_puppet_pos) -> void:
	if puppet_position == new_puppet_pos:
		return
	puppet_position = new_puppet_pos
	tween.interpolate_property(
		self, "global_position", global_position, puppet_position, 0.001
		)
	tween.start()



func _physics_process(_delta) -> void:
	if is_network_master() and is_instance_valid(self):
		global_position.x = wrapf(global_position.x, 0, screen_size.x)
		global_position.y = wrapf(global_position.y, 0, screen_size.y)
		
	elif not is_network_master() and is_instance_valid(self):
		if puppet_position and puppet_rotation:
			global_position = puppet_position
			rotation = puppet_rotation

	velocity = move_and_slide(velocity)


func _on_Hitbox_area_entered(area : Area2D) -> void:
	var hurtbox := area as Hurtbox
	if not hurtbox:
		return
	else:
		if is_network_master() and is_instance_valid(self):
			rpc("projectile_death")


func _on_Lifetime_timeout() -> void:
	if is_network_master() and is_instance_valid(self):
		rpc("projectile_death")


#	This func must be remotesync since the projectile must dissapear
#	on all devices.
remotesync func projectile_death() -> void:
	lifetime.stop()
	$Tween.stop_all()
	$NetworkTickRate.stop()
#	print("%s destroyed at %s." % [self.name, OS.get_system_time_secs()])
	_extra_effect()
#	print("Destroying: %s" % self.name)
	queue_free()


# Function used by other types of projectiles on despawn.
func _extra_effect() -> void:
	pass


func _on_network_tick() -> void:
	if is_network_master() and is_instance_valid(self):
		rset_unreliable("puppet_position", global_position)
		rset_unreliable("puppet_rotation", rotation)

#func _destructor() -> void:
#	lifetime.stop()
#	$Tween.stop_all()
#	$NetworkTickRate.stop()
#
#
#func _create() -> void:
#	print(OS.get_system_time_secs())



func _ready() -> void:
	velocity = impulse.rotated(rotation)
	set_as_toplevel(true)
	lifetime.start()
	if is_network_master() and is_instance_valid(self):
		rset_unreliable("puppet_position", global_position)
		rset_unreliable("puppet_rotation", rotation)
#	var _err_destructor = connect("tree_exiting", self, "_destructor")
#	var _err_creator = connect("tree_entered", self, "_create")
