class_name Pawn
extends SGKinematicBody2D
# Spaceship controlled by Players

const FIXED_POINT_NUM := 65536
const ACCELERATION := 200
const ROTATION_SPEED := FIXED_POINT_NUM*1
const MAX_THRUST := FIXED_POINT_NUM*2

var engine_power := FIXED_POINT_NUM*1
var thrust := 0
var rotation_dir := 0 
var thrust_dir := 0
var velocity := SGFixedVector2.new()

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
	
	fixed_rotation += SGFixed.from_float(rotation_dir * ROTATION_SPEED)
	thrust = SGFixed.from_float(clamp(thrust_dir * engine_power, -MAX_THRUST, 0))
	
	# Screen wrapping
#	fixed_position_x = SGFixed.from_float(wrapf(fixed_position_x, 0, screen_size.x*FIXED_POINT_NUM))
#	fixed_position_y = SGFixed.from_float(wrapf(fixed_position_y, 0, screen_size.y*FIXED_POINT_NUM))

	velocity.y = thrust
#	.rotated(fixed_rotation)
	move_and_slide(velocity)


func _save_state() -> Dictionary:
	return {
		fixed_position = fixed_position,
		fixed_rotation = fixed_rotation,
		thrust = thrust,
		velocity = velocity,
	}


func _load_state(state: Dictionary) -> void:
	fixed_position = state["fixed_position"]
	fixed_rotation = state["fixed_rotation"]
	thrust = state["thrust"]
	velocity = state["velocity"]


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
		velocity.iadd(Vector2(0, hitbox.knockback).rotated(get_angle_to(hitbox.position)))


# TODO : Remotesync? Needed for synced health_ui?
remotesync func take_damage(damage : int) -> void:
	stats.health -= damage


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
	velocity = SGFixedVector2.ZERO
	thrust_dir = 0
	self.position = get_parent().global_position
	self.show()
