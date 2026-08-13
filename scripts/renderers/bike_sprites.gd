class_name BikeSprites
extends RefCounted

# Can't rely on animation_player here, as we have to draw our sprites ourselves
# This file defines the various animations and playin gspeeds. 
# contains a bunch of static funcs used by the renderers

const CELL_SIZE := 32.0

# TODO: use enums here instead
const ANIMS := {
	"stopped":  {"frames": [Vector2i(0, 0)], "fps": 1.0, "loop": false},
	"starting": {"frames": [Vector2i(0, 0), Vector2i(1, 0)], "fps": 8.0, "loop": true},
	"lean_0":   {"frames": [Vector2i(0, 1), Vector2i(1, 1)], "fps": 8.0, "loop": true},
	"lean_1":   {"frames": [Vector2i(0, 2), Vector2i(1, 2)], "fps": 8.0, "loop": true},
	"lean_2":   {"frames": [Vector2i(0, 3), Vector2i(1, 3)], "fps": 8.0, "loop": true},
	"punch":    {"frames": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)], "fps": 12.0, "loop": false},
	"kick":     {"frames": [Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)], "fps": 12.0, "loop": false},
	"crash":    {"frames": [Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6)], "fps": 10.0, "loop": false},
	"floored":  {"frames": [Vector2i(6, 6)], "fps": 1.0, "loop": false},
	"recover":  {"frames": [Vector2i(0, 7)], "fps": 1.0, "loop": false},
	"running":  {"frames": [Vector2i(0, 8), Vector2i(1, 8)], "fps": 8.0, "loop": true},
	"mounting": {"frames": [Vector2i(0, 7), Vector2i(1, 6), Vector2i(0, 6)], "fps": 8.0, "loop": false},
}

const LEAN_STEPS := 2 # lean_0, laen_1 and lean_2
const RIDE_SCALE_MAX := 6.0
const RIDE_SCALE_MIN := 0.5 # how fast/slow to play the animations depending on speed
const STOPPED_RATIO := 0.01 # speed ratio under which we show "stopped"
const STARTING_RATIO := 0.08 # speed ratio under which we show "starting"

# when leaning, move the shadow so that it matches teh center of the bike
const SHADOW_OFFSETS := { 
	"lean_0": 0.0,
	"lean_1": -5.2,
	"lean_2": -4.2,
}

static func get_riding_anim(speed_ratio: float, lean: float) -> String:
	if speed_ratio < STOPPED_RATIO:
		return "stopped"
	if speed_ratio < STARTING_RATIO:
		return "starting"
	return "lean_%d" % int(round(absf(lean) * LEAN_STEPS))

static func get_ride_scale(speed_ratio: float) -> float:
	return lerpf(RIDE_SCALE_MIN, RIDE_SCALE_MAX, speed_ratio)

static func should_mirror(anim: String, lean: float) -> bool:
	# no need to mirror upright frames
	return lean < 0.0 and anim.begins_with("lean_")

static func get_shadow_offset(anim: String, flip_h: bool) -> float:
	var offset: float = SHADOW_OFFSETS.get(anim, 0.0)
	return -offset if flip_h else offset
