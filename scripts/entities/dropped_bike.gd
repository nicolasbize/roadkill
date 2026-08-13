class_name DroppedBike
extends RefCounted

# Bike lying on the road after a crash

var active := false
var x := 0.0
var z := 0.0

func place(pos_x: float, pos_z: float) -> void:
	x = pos_x
	z = pos_z
	active = true

func clear() -> void:
	active = false
