class_name Car
extends RefCounted

# Main entity that makes traffic
# created and handled by TrafficProcessor, rendered by TrafficRenderer

const CELL_SIZE := 32.0 
const CLOSE_DISTANCE := 8.0 # when to switch from close to rear
const CLOSE_FRAME := 0 # shows a slight rotation to fake 3d
const FRAMES := 2
const REAR_FRAME := 1

var direction := -1.0 # -1 is against the track
var frame := 0
var frame_timer := 0.0
var speed := 0.0 # m/s
var texture_index := 0
var warned := false # warning sign for the player
var x := 0.0
var z := 0.0

func get_frame(distance: float) -> int:
	if direction > 0.0:
		return CLOSE_FRAME if distance < CLOSE_DISTANCE else REAR_FRAME
	return frame
