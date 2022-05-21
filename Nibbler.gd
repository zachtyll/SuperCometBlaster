extends KinematicBody2D

enum {IDLE, CHASE}

const PUSH := 10

export(int) var score
export(float) var rotation_speed = 200
export(float) var engine_thrust = 100

puppet var puppet_position setget puppet_position_set
puppet var puppet_rotation setget puppet_rotation_set
# Physics
var velocity := Vector2.ZERO
var impulse := Vector2.ZERO

var ai_state = IDLE
var thrust = Vector2.ZERO
var thrust_direction = 0
var rotation_direction = 0

var target = null

onready var tween := $Tween
onready var knockback = $Hitbox.knockback
onready var stats = $Stats
onready var comet_radius = $CollisionShape2D.shape.radius
onready var seek_zone = $SeekZone
onready var sprite = $NibblerSprite
onready var screen_size = get_viewport_rect().size

signal spawn
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
	
	velocity = move_and_slide(velocity, Vector2.UP,
			false, 4, PI/4, false)

	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * PUSH)


func _process(delta):
	match ai_state:
		IDLE:
			sprite.play("Idle")
			thrust = Vector2.ZERO
			seek_target()
		CHASE:
			sprite.play("Chase")
			var target = seek_zone.target
			if target and is_instance_valid(target):
				var dest_vector = target.get_global_transform().origin - get_global_transform().origin
				velocity = velocity.move_toward(dest_vector , delta * 100)
				rotation = velocity.angle()
			seek_target()


func seek_target():
	if seek_zone.can_see_target():
		ai_state = CHASE
	else:
		ai_state = IDLE


func _on_Hurtbox_area_entered(area):
	if not is_network_master():
		return
	stats.health -= area.damage


remotesync func comet_death() -> void:
	# This signal is sent to:
	# - Objective Manager
	self.emit_signal("despawn", self)
	self.queue_free()


func _on_TickRate_timeout():
	if is_network_master() and is_instance_valid(self):
		rset_unreliable("puppet_position", global_position)


func _on_Stats_no_health():
	rpc("comet_death")


func _ready():
	velocity = Vector2.ZERO
	add_to_group("Enemies")
	add_to_group("Aliens")
	add_to_group("Nibbler")
	emit_signal("spawn", self)


func _on_SeekZone_new_target(new_target) -> void:
	target = new_target
	_notify_aliens()


func _notify_aliens() -> void:
	var nibblers = get_tree().get_nodes_in_group("Nibbler")
	for nibbler in nibblers:
		nibbler.seek_zone.target = target
