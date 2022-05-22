class_name Pawn
extends KinematicBody2D
# Player spaceship, controlled by 

const ACCELERATION := 200

const ROTATION_DAMPING := 20
const MAX_THRUST := 10


var engine_power := 1
var thrust := 0
var rotation_dir := 0 
var thrust_dir := 0
var velocity := Vector2.ZERO

onready var weapon := $WeaponRegular
onready var shield := $Shield
onready var stats := $PlayerStats
onready var tween := $Tween
onready var screen_size := get_viewport_rect().size

# Signals to:
#	- Objective Manager
signal pawn_death


func _get_local_input() -> Dictionary:
	var input_rotation := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var input_thrust := -Input.get_action_strength("ui_up")
	
	var shooting := Input.is_action_pressed("shoot")
	
	
	var input := {}
	if not input_rotation == 0 or not input_thrust == 0:
		input["input_vector"] = Vector2(input_rotation, input_thrust)
		input["shooting"] = shooting
	
	return input



func _network_process(input: Dictionary) -> void:
	
	thrust_dir = input.get("input_vector", Vector2.ZERO).y
	rotation_dir = input.get("input_vector", Vector2.ZERO).x
	
	rotation += rotation_dir / float(ROTATION_DAMPING)
	thrust = int(clamp(thrust_dir * engine_power, -MAX_THRUST, 0))

	global_position.x = wrapf(global_position.x, 0, screen_size.x)
	global_position.y = wrapf(global_position.y, 0, screen_size.y)

	velocity += Vector2(0, thrust).rotated(rotation)
	velocity = move_and_slide(velocity)



func _save_state() -> Dictionary:
	return {
		position = position,
		rotation = rotation,
	}


func _load_state(state: Dictionary) -> void:
	position = state["position"]
	rotation = state["rotation"]


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
