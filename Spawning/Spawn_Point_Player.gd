extends Node2D

signal player_death

export(NodePath) onready var players = get_node(players) as Node2D

onready var player_scene = load("res://Player/PlayerController.tscn")

func _ready() -> void:
	if not get_tree().network_peer != null:
		call_deferred("spawn_player")
		print("Spawning player!")
	else:
		queue_free()

func spawn_player() -> void:
	var player_instance = player_scene.instance()
	player_instance.position = get_node("SpawnPosition").get_global_position()
	player_instance.rotation = get_node("SpawnPosition").get_global_rotation()
	players.add_child(player_instance)
	player_instance.pawn.connect("player_death", self, "evaluate_death")
	


func evaluate_death(value: RigidBody2D):
	emit_signal("player_death", value)
