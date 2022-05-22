class_name Pawn
extends SGKinematicBody2D
# Spaceship controlled by Players

const FIXED_POINT_NUM := 65536
const ACCELERATION := 200
const ROTATION_SPEED := FIXED_POINT_NUM*2000
const MAX_THRUST := FIXED_POINT_NUM*1000

var engine_power := FIXED_POINT_NUM*100
var thrust := 0
var rotation_dir := 0 
var thrust_dir := 0
var velocity := SGFixedVector2.new()

var origin := SGFixedVector2.new()

onready var weapon := $WeaponRegular
onready var shield := $Shield
onready var stats := $PlayerStats
onready var tween := $Tween
onready var screen_size := get_viewport_rect().size * FIXED_POINT_NUM

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

	thrust = SGFixed.mul(thrust_dir, engine_power)
	velocity.iadd(SGFixed.vector2(0, thrust).rotated(fixed_rotation))

	# Screen wrapping
	if fixed_position.x > screen_size.x:
		fixed_position.x = 0
	if fixed_position.x < 0:
# warning-ignore:narrowing_conversion
		fixed_position.x = screen_size.x
	if fixed_position.y > screen_size.y:
		fixed_position.y = 0
	if fixed_position.y < 0:
# warning-ignore:narrowing_conversion
		fixed_position.y = screen_size.y

# warning-ignore:return_value_discarded
	rotate_and_slide(SGFixed.mul(rotation_dir, ROTATION_SPEED))
	velocity = move_and_slide(velocity)


func _save_state() -> Dictionary:
	return {
		fixed_position = fixed_position,
		fixed_rotation = fixed_rotation,
		velocity = velocity
	}


func _load_state(state: Dictionary) -> void:
	fixed_position = state["fixed_position"]
	fixed_rotation = state["fixed_rotation"]
	velocity = state["velocity"]


func _on_Hurtbox_area_entered(area: Area2D) -> void:
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
