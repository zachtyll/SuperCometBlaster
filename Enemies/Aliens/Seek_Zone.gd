extends Area2D

var target = null

signal new_target

func can_see_target():
	return target != null


func _on_SeekZone_area_entered(area):
	target = area.owner
	emit_signal("new_target", target)


func _on_SeekZone_area_exited(_area):
	target = null
	emit_signal("new_target", target)
