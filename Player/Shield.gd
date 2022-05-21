extends Node2D
# Protects player health.

var active := true

onready var stats := $Stats
onready var animation := $AnimatedSprite


func activate_shield() -> void:
	pass
	# Play a "shields-up" animation here.


func _on_Hurtbox_area_entered(area) -> void:
	if not is_network_master():
		return

	var hitbox := area as Hitbox
	if not hitbox:
		return
	# Ignore self.
	elif hitbox.owner is Pawn:
		return
	else:
#		print(str(hitbox.get_parent().name) + " is attacking " + str(self.name))
		stats.health -= hitbox.damage
		owner.velocity = Vector2(0, -hitbox.knockback).rotated(rotation)


func _on_Stats_no_health() -> void:
	self.active = false
	# Play a "shields-down" animation here.


func _on_Stats_health_changed(health : int):
#	print("SHIELDED! %s HP left." % health)
	if animation:
		var fade := float(health)/10
		# Percentual colour values.
		animation.set_modulate(Color(1, 1, 1, fade))
