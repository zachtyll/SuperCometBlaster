extends Node2D

export(float) var health_chance = 0

export(NodePath) onready var loot = get_node(loot) as Node2D
onready var health_pickup = load("res://Pickups/Health_Pickup.tscn")
onready var rng = RandomNumberGenerator.new()
onready var spawn_point = $SpawnPoint

enum comet_size {SIZE_LARGE, SIZE_MEDIUM, SIZE_SMALL}

remotesync func _on_Spawn_Point_Comet_enemy_death(value):
	rng.randomize()
	var loot_result = rng.randf_range(0, 1)
	if value.is_in_group("Comet"):
		if value.comet_size == comet_size.SIZE_LARGE:
			if loot_result > health_chance:
				call_deferred("spawn_loot", value)
			else:
				pass


remotesync func spawn_loot(value):
	var health_pickup_instance = health_pickup.instance()
	health_pickup_instance.set_global_transform(value.get_global_transform())
	health_pickup_instance.set_angular_velocity(value.get_angular_velocity())
	health_pickup_instance.set_linear_velocity(value.get_linear_velocity())
#	loot.add_child(health_pickup_instance)
