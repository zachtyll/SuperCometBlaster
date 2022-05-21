extends Node
class_name EntityReporter

export(NodePath) onready var entity_container = get_node(entity_container) as Node2D
export(PackedScene) onready var entity_type

# Called when the node enters the scene tree for the first time.
func _ready():
	set_network_master(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
