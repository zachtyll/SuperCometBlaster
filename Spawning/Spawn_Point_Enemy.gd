extends Node2D

onready var comet_scene = load("res://Enemies/Comet.tscn")
onready var medium_comet_scene = load("res://Enemies/Comet_Medium.tscn")
onready var small_comet_scene = load("res://Enemies/Comet_Small.tscn")
onready var rng = RandomNumberGenerator.new()

enum comet_size {SIZE_LARGE, SIZE_MEDIUM, SIZE_SMALL}

signal enemy_spawn
signal enemy_death

func _ready():
	print("Ready!")

# Evaluates the type of enemy that has died.
# TODO: Specific for Comets? 
# TODO: Make more pretty.
func evaluate_death(value):
	emit_signal("enemy_death", value)
	if value.comet_size == comet_size.SIZE_LARGE:
		call_deferred("spawn_comet", value.position, value.get_angular_velocity(), value.get_linear_velocity(), 2, medium_comet_scene)
	elif value.comet_size == comet_size.SIZE_MEDIUM:
		call_deferred("spawn_comet", value.position, value.get_angular_velocity(), value.get_linear_velocity(), 2, small_comet_scene)
	else:
		pass

# Spawns a new Comet. This comet is tracked when alive
# and tells the Objective Manager if it is destroyed.
func spawn_comet(position, angular_velocity, linear_velocity, amount, comet_type):
	for _comet in range(amount):
		rng.randomize()
		var random_rotation = rng.randf_range(0, 360)
		var comet_instance = comet_type.instance()
		var world = get_tree().current_scene
		comet_instance.set_position(position)
		comet_instance.set_rotation(random_rotation)
		comet_instance.set_angular_velocity(angular_velocity)
		comet_instance.set_linear_velocity(linear_velocity)
#		comet_instance.apply_central_impulse(Vector2(10, 0).rotated(random_rotation))
		comet_instance.connect("enemy_death", self, "evaluate_death")
		world.add_child(comet_instance)
		emit_signal("enemy_spawn", comet_instance)


func _on_Level_Manager_update_level_begin(value):
	for _level in range(value):
#		rng.randomize()
#		var random_rotation = rng.randf_range(0, 360)
#		print(self.rotation) 
		call_deferred("spawn_comet", self.position, 0, Vector2(10 * value/2 , 0), 1, comet_scene)
