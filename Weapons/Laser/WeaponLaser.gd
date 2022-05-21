extends Node2D
# Laserstrålevapen. Fungerar inte. (UNUSED). 

onready var projectile_scene : PackedScene = $WeaponStats.projectile
onready var fire_rate : float = $WeaponStats.fire_rate
onready var line := $CastPoint/Line2D
onready var raycast := $CastPoint/RayCast2D

var active := false
var temperature := 0.0
var overheated := false


master func fire_weapon() -> void:
	if not is_network_master():
		return
	
	active = not active
	
	if not overheated and active:
		_pre_spawn_laser()


func _pre_spawn_laser() -> void:
	print("pow")
	var target = raycast.get_collider()
	if target:
		print(self.global_position.distance_to(target.global_position))
		var length := self.global_position.distance_to(target.global_position)
		line.set_point_position(1, Vector2(0, length))
		if target.owner.has_method("comet_death"):
			target.owner.rpc("comet_death", 2)

func _ready() -> void:
	$Timer.set_wait_time(fire_rate)


func _on_Timer_timeout():
	if active:
		temperature = move_toward(temperature, 5, 1)
		print(temperature)
	else:
		temperature = move_toward(temperature, 0, 1)
		print(temperature)
	
	if temperature < 5:
		overheated = false
	elif overheated and temperature == 0:
		overheated = false
	elif temperature == 5:
		overheated = true
		print("OVERHEAT!")
#		if owner.has_method("take_damage"):
#			owner.rpc("take_damage", 2)
#			active = false
	else:
		push_warning("Unkown problem in WeaponLaser.")
