class_name Pawn
extends KinematicBody2D
# Player spaceship, controlled by 

const ACCELERATION := 200

export (float) var rotation_speed := 200.0
export (float) var engine_thrust := 100.0

#puppet var puppet_position setget puppet_position_set
#puppet var puppet_rotation setget puppet_rotation_set

var thrust := Vector2.ZERO
var rotation_dir := 0 setget set_rotation_dir
var thrust_dir := 0 setget set_thrust_dir

var velocity := Vector2.ZERO

onready var weapon := $WeaponRegular
onready var shield := $Shield
onready var stats := $PlayerStats
onready var tween := $Tween
onready var screen_size := get_viewport_rect().size

# Signals to:
#	- Objective Manager
signal pawn_death


func set_rotation_dir(value) -> void:
	rotation_dir = value


func set_thrust_dir(value) -> void:
	thrust_dir = value


master func call_steer(direction : int) -> void:
	rotation_dir = direction


master func call_thrust(direction : int) -> void:
	thrust_dir = direction


#func puppet_rotation_set(new_puppet_rot) -> void:
#	if puppet_rotation == new_puppet_rot:
#		return
#	puppet_rotation = new_puppet_rot
#	tween.interpolate_property(
#		self, "rotation", rotation, puppet_rotation, 0.001
#		)
#	tween.start()
#
#
## Tweens to the newly set global position from the old position.
#func puppet_position_set(new_puppet_pos) -> void:
#	if puppet_position == new_puppet_pos:
#		return
#	puppet_position = new_puppet_pos
#	tween.interpolate_property(
#		self, "global_position", global_position, puppet_position, 0.001
#		)
#	tween.start()

#
#func _get_local_input() -> Dictionary:
#
#	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#
#	var input := {}
#	if not input_vector == Vector2.ZERO:
#		input["input_vector"] = input_vector
#
#	return input



func _network_process(input: Dictionary) -> void:
	
	rotation += rotation_dir / rotation_speed


	thrust = thrust_dir * Vector2(0, 0.1)
	
#	thrust.move_toward(
#		input.get("input_vector", Vector2.ZERO).y * Vector2(0, engine_thrust),
#		engine_thrust, ACCELERATION)
#	)

	global_position.x = wrapf(global_position.x, 0, screen_size.x)
	global_position.y = wrapf(global_position.y, 0, screen_size.y)

	velocity += thrust.rotated(rotation)
	velocity = move_and_slide(velocity)



func _save_state() -> Dictionary:
	return {
		position = position,
	}


func _load_state(state: Dictionary) -> void:
	position = state["position"]


#func _physics_process(delta) -> void:
#	if is_network_master() and is_instance_valid(self):
#		thrust = thrust.move_toward(
#			thrust_dir * Vector2(0, engine_thrust),
#			delta * ACCELERATION
#		)
#
#		rotation += rotation_dir / rotation_speed
#
#		velocity += thrust.rotated(rotation) * delta
#
#		global_position.x = wrapf(global_position.x, 0, screen_size.x)
#		global_position.y = wrapf(global_position.y, 0, screen_size.y)
#
#	elif not is_network_master() and is_instance_valid(self):
#		if puppet_position and puppet_rotation:
#			global_position = puppet_position
#			rotation = puppet_rotation
#
#	velocity = move_and_slide(velocity)


func _on_Hurtbox_area_entered(area: Area2D) -> void:
	if not is_network_master():
		return

	# Filter for hitboxes.
	var hitbox := area as Hitbox
	if not hitbox:
		return
	
	if shield.active:
		return
	else:
#		print(str(hitbox.get_parent().name) + " is attacking " + str(self.name))
		rpc("take_damage", hitbox.damage)
		velocity += Vector2(0, hitbox.knockback).rotated(get_angle_to(hitbox.position))
#		self.apply_central_impulse()


# TODO : Remotesync? Needed for synced health_ui?
remotesync func take_damage(damage : int) -> void:
	stats.health -= damage


#	Sets the global position of the network master
#	to the puppet position in remotes via rset().
#	Activates setter which begins tweening.
#func _on_Network_Tick_Rate_timeout() -> void:
#	if is_network_master() and is_instance_valid(self):
#		rset_unreliable("puppet_position", global_position)
#		rset_unreliable("puppet_rotation", rotation)


func _on_PlayerStats_no_health() -> void:
	rpc("pawn_death")


# TODO : Refactor.
remotesync func pawn_death() -> void:
	# Caught by:
	# - Banner_UI
	# - Player_Controller
	emit_signal("pawn_death")
	self.hide()


# TODO: move this function into something else.
remotesync func pawn_respawn() -> void:
	stats.health = stats.max_health
	shield.stats.health = shield.stats.max_health
	velocity = Vector2.ZERO
	thrust_dir = 0
	self.position = get_parent().global_position
	self.show()


#func _ready() -> void:
#	if is_network_master() and is_instance_valid(self):
#		rset_unreliable("puppet_position", global_position)
#		rset_unreliable("puppet_rotation", rotation)
