class_name AreaOfEffect
extends Node2D
# Generic class for areas of effect.

# Scoring
export var score := 0

var effect := null
var within_area := []

signal spawn
signal despawn

remotesync func _remove_area() -> void:
	emit_signal("despawn", self)
	self.queue_free()


func _on_AnimationPlayer_animation_finished(_anim_name):
	if not is_network_master():
		return
	rpc("_remove_area")


func _ready():
	emit_signal("spawn", self)
