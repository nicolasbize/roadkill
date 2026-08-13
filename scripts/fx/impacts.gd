class_name Impacts
extends RefCounted

# Spark FX entity 

var points: Array[Dictionary] = []
 
func add(kind: String, x: float, z: float, ) -> void:
	points.append({"kind": kind, "x": x, "z": z})
 
func clear() -> void:
	points.clear()
