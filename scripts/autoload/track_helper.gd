extends Node

# global utility class.

const ROAD_SEGMENT_LENGTH := 1.0 # m
const ROAD_HALF_WIDTH := 8.0 # m

# a bend of radius r moves sideways by z^2/2r
func curve_for_radius(radius: float) -> float:
	return ROAD_SEGMENT_LENGTH * ROAD_SEGMENT_LENGTH / radius

# manual easing
func ease_in_out(from: float, to: float, t: float) -> float:
	return lerpf(from, to, smoothstep(0.0, 1.0, t))

func kmh_to_ms(kmh: float) -> float:
	return kmh / 3.6

func ms_to_kmh(ms: float) -> float:
	return ms * 3.6
