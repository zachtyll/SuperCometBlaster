extends Node2D

remotesync var random_point_index: int = 0
remotesync var random_rotation: int = 0
remotesync var spawn_position: Vector2 = Vector2.ZERO
remotesync var random_result: float = 0.0

export(NodePath) onready var enemies = get_node(enemies) as Node2D
export(NodePath) onready var objective_manager = get_node(objective_manager) as Node

var synced_peers := 0
var data_array := []
var enemy_data

onready var comet_regular := preload("res://Enemies/Comets/Regular/CometRegular.tscn")
onready var comet_infected := preload("res://Enemies/Comets/Infected/CometInfected.tscn")
onready var comet_explosive := preload("res://Enemies/Comets/Explosion/CometExplosive.tscn")
onready var comet_ice := preload("res://Enemies/Comets/Ice/CometIce.tscn")
onready var alien_nibbler := preload("res://Enemies/Aliens/Nibbler.tscn")

onready var enemy_array := [
	comet_regular,
	comet_infected,
	comet_explosive,
	comet_ice,
	alien_nibbler
]

onready var rng := RandomNumberGenerator.new()
onready var center_of_screen := get_viewport_rect().size * Vector2(0.5, 0.5)
onready var path := $Path2D
onready var spawn_point := $Path2D/SpawnPoint
onready var baked_point_list = path.get_curve().get_baked_points()


func pre_spawn_comet(amount : int) -> void:
	for _comet in range(amount):
		var random = rng.randi_range(0, enemy_array.size() - 1)
		var comet_name := ""
		match(random):
			0, 1, 2, 3:
				comet_name = "Comet"
			4:
				comet_name = "Nibbler"
			_:
				print("Somekind of error: %s" % random)
		
		enemy_data = {
			"impulse" : Vector2(50, 0).rotated(get_angle_to(center_of_screen) + random_rotation),
#			"global_position" : spawn_point.global_position,
			"global_transform" : spawn_point.global_transform,
			"rotation" : random_rotation,
			"enemy_name" : comet_name + "_" + str(Gamestate.networked_object_name_index),
			"scene_number" : random,
		}
		rpc("spawn_comet", enemy_data)


# TODO : Even cooler if we signal for death, then have "emitter-classes"
# For releasing all extra effects. This will most likely scale better too. 
remotesync func spawn_comet(data) -> void:
	var enemy_instance = enemy_array[data.scene_number].instance()
	enemy_instance.name = data.enemy_name
	if not enemy_instance is KinematicBody2D:
		enemy_instance.apply_central_impulse(data.impulse)
	else:
		enemy_instance.impulse = data.impulse
	enemy_instance.global_transform = data.global_transform
	enemy_instance.rotation = data.rotation
	
	var _err_enemy_death = enemy_instance.connect("despawn", objective_manager, "_on_enemy_death")
	var _err_enemy_spawn = enemy_instance.connect("spawn", objective_manager, "_on_enemy_spawn")

	Gamestate.global_spawn(enemy_instance)


master func begin_new_level(level: int) -> void:

#		print("NEW LEVEL !")
	for _levels in range(level):
		rng.randomize()
# warning-ignore:narrowing_conversion
		random_rotation = rng.randf_range(0, 360)
		spawn_point.offset = rng.randi()
		pre_spawn_comet(0)


func _ready():
	set_network_master(1)
