class_name TrafficWarning
extends RefCounted

# flashes a warning to help the player avoid crashing into traffic

const LEAD_TIME := 1.5 # s before contact
const DURATION := 1.0
const BLINK_RATE := 5.0 # amount/s
const MARKER_DISTANCE := 6.0

var timer := 0.0
var car: Car = null

func update(dt: float, cars: Array[Car], track: Track, bike_z: float, bike_speed: float) -> void:
	timer = maxf(timer - dt, 0.0)
	if timer > 0.0:
		return

	for candidate in cars:
		if candidate.warned:
			continue
		var gap_z := track.gap_z(candidate.z, bike_z)
		if gap_z <= 0.0:
			continue
		var closing := bike_speed - candidate.direction * candidate.speed
		if closing <= 0.0:
			continue # getting further away, skip
		if gap_z / closing <= LEAD_TIME:
			candidate.warned = true
			car = candidate
			timer = DURATION
			return

func is_flashing() -> bool:
	# time can tell if we're flashing or not
	return timer > 0.0 and fmod(timer * BLINK_RATE, 1.0) > 0.5

# place marker above road lane the car is in
func get_screen_x(camera: RoadCamera, road: RoadRenderer) -> float:
	if car == null:
		return RoadCamera.VIEWPORT_WIDTH * 0.5
	var offset := 0.0
	var ground := road.get_info(MARKER_DISTANCE)
	if not ground.is_empty():
		offset = ground.offset
	return camera.project_x(offset + car.x, MARKER_DISTANCE)
