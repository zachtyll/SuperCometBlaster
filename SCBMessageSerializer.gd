extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"


func serialize_input(input: Dictionary) -> PoolByteArray:
	return var2bytes(input)
