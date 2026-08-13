class_name Prop
extends RefCounted

# Any static prop in the level

const DEFAULT_MAX_DISTANCE := 60.0

var x := 0.0 # m. from center of the road
var z := 0.0
var kind := "" # maps name provided in exported world dictionary
var flip_h := false
var hit_radius := 0.0
var max_distance := DEFAULT_MAX_DISTANCE # start/finish rendered from further away
var world_scale := 1.0 # some objects need to be rendered bigger eg palm trees
var world_width := 0.0 # m to stretch the sprite (useful for gantries)
