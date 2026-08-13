class_name Track
extends Resource

# the road is a long list of straight segments with curve info to fake curves in the distance
# adding curves creates a series of segments with interpolated offsets

const LEFT := -1
const RIGHT := 1
const DEFAULT_PROP_SPACING := 6 # default spacing between props, overriden by scenary info
const DEFAULT_SCENERY_OFFSET := 4.0 # default space from road edge
const DEFAULT_SCENERY_JITTER := 2.0 # default flucutation of 0-2m
const GANTRY_DISTANCE := 150.0 # how far away to show start/finish
const GANTRY_WIDTH := 18.0 # slightly more than the road
const HIT_BUCKET := 8.0 # allows to optimize collision detection
const VERGE := 1.5 # where to place left / right turn warnings

# some static props that don't change names from one track to another
const TREE := "tree"
const ROCK := "rock"
const SIGN_LEFT := "turn_left"
const SIGN_RIGHT := "turn_right"
const START := "start"
const FINISH := "finish"

var crash_buckets := {}
var current_y := 0.0
var finish_z := 0.0
var props: Array[Prop] = []
var segments: Array[Dictionary] = []

# custom info about how to render / collide with special props
const PROP_STYLES := {
	TREE: {"scale": 2.0, "max_distance": 120.0, "hit_radius": 0.8},
	ROCK: {"hit_radius": 1.2},
	START: {"max_distance": GANTRY_DISTANCE},
	FINISH: {"max_distance": GANTRY_DISTANCE},
}

func apply_style(prop: Prop) -> void:
	var style: Dictionary = PROP_STYLES.get(prop.kind, {})
	prop.world_scale = style.get("scale", 1.0)
	prop.max_distance = style.get("max_distance", Prop.DEFAULT_MAX_DISTANCE)
	prop.hit_radius = style.get("hit_radius", 0.0)

func add_prop(kind: String, side: int, offset := VERGE, flip_h := false) -> void:
	add_prop_at(segments.size(), kind, side, offset, flip_h)

func add_prop_at(index: int, kind: String, side: int, offset := VERGE, flip_h := false) -> void:
	var prop := Prop.new()
	prop.z = index * TrackHelper.ROAD_SEGMENT_LENGTH
	prop.x = side * (TrackHelper.ROAD_HALF_WIDTH + offset)
	prop.kind = kind
	prop.flip_h = flip_h
	apply_style(prop)
	props.append(prop)

func add_prop_run(kind: String, side: int, length: int, spacing := DEFAULT_PROP_SPACING, offset := VERGE, flip_h := false) -> void:
	var start := segments.size()
	var step := maxi(spacing, 1)
	for i in range(0, length, step):
		add_prop_at(start + i, kind, side, offset, flip_h)

# add props to both sides of the road at the same time
func add_scenery_run(kinds: Array[String], length: int, spacing := DEFAULT_PROP_SPACING, offset := DEFAULT_SCENERY_OFFSET, jitter := DEFAULT_SCENERY_JITTER, start := -1) -> void:
	var from := segments.size() if start < 0 else start
	var step := maxi(spacing, 1)
	add_verge_run(from, kinds, LEFT, length, step, offset, jitter)
	add_verge_run(from + int(step / 2.0), kinds, RIGHT, length, step, offset, jitter)

func add_verge_run(start: int, kinds: Array[String], side: int, length: int, step: int, offset: float, jitter: float) -> void:
	var i := 0
	while i < length:
		add_prop_at(start + i, kinds.pick_random(), side, offset + randf_range(-jitter, jitter), randf() < 0.5)
		i += maxi(step + randi_range(-1, 1), 1) # prevent 0s

# keep track of the props that we can collide / crash with
# use buckets of segments so we don't do collision detection with the entire list of props
func index_crashables() -> void:
	crash_buckets.clear()
	for prop in props:
		if prop.hit_radius <= 0.0:
			continue
		var b := int(prop.z / HIT_BUCKET)
		if not crash_buckets.has(b):
			crash_buckets[b] = []
		crash_buckets[b].append(prop)

func add_gantry(kind: String, width := GANTRY_WIDTH) -> void:
	var prop := Prop.new()
	prop.z = segments.size() * TrackHelper.ROAD_SEGMENT_LENGTH
	prop.x = 0.0
	prop.kind = kind
	apply_style(prop)
	prop.world_width = width
	prop.max_distance = GANTRY_DISTANCE
	props.append(prop)

func add_finish_line(kind := "finish") -> void:
	finish_z = segments.size() * TrackHelper.ROAD_SEGMENT_LENGTH
	add_gantry(kind)

func get_total_length() -> float:
	return segments.size() * TrackHelper.ROAD_SEGMENT_LENGTH

# get y position at specific z distance
func get_elevation_at(distance: float) -> float:
	# lerp between two segments
	var index := int(floor(distance / TrackHelper.ROAD_SEGMENT_LENGTH))
	var t := fposmod(distance, TrackHelper.ROAD_SEGMENT_LENGTH) / TrackHelper.ROAD_SEGMENT_LENGTH
	return lerpf(get_segment(index).y, get_segment(index + 1).y, t)

# returns clamped z to prevent going beyong track
func get_track_z(distance: float) -> float:
	return clampf(distance, 0.0, get_total_length())

# return clamped segment to prevent going beyond track
func get_segment(index: int) -> Dictionary:
	return segments[clampi(index, 0, segments.size() - 1)]

# simlar to distance_to
func gap_z(target_z: float, from_z: float) -> float:
	return target_z - from_z

# used to push the player towards the edge during turn
func get_curvature_at(distance: float) -> float:
	var index := int(floor(distance / TrackHelper.ROAD_SEGMENT_LENGTH))
	var length := TrackHelper.ROAD_SEGMENT_LENGTH
	return get_segment(index).curve / (length * length)

func add_segment(curve: float, y: float) -> void:
	segments.append({"curve": curve, "y": y})

func add_straight(count: int, kind := "", side := RIGHT, spacing := DEFAULT_PROP_SPACING) -> void:
	if kind != "":
		add_prop_run(kind, side, count, spacing)
	for i in count:
		add_segment(0.0, current_y)

func add_road(enter: int, hold: int, leave: int, curve: float, height: float) -> void:
	var start_y := current_y
	var end_y := start_y + height
	var total := enter + hold + leave
	for i in total:
		# ease in/out the elevation for more realistic hillclimbing
		var y := TrackHelper.ease_in_out(start_y, end_y, float(i) / total)
		# same for curves
		var curvature := 0.0
		if i < enter:
			curvature = TrackHelper.ease_in_out(0.0, curve, float(i) / enter)
		elif i < enter + hold:
			curvature = curve
		else:
			curvature = TrackHelper.ease_in_out(curve, 0.0, float(i - enter - hold) / leave)
		add_segment(curvature, y)
	current_y = end_y

func add_curve(enter: int, hold: int, leave: int, radius: float) -> void:
	add_road(enter, hold, leave, TrackHelper.curve_for_radius(radius), 0.0)

func add_hill(enter: int, hold: int, leave: int, height: float) -> void:
	add_road(enter, hold, leave, 0.0, height)

func add_curved_hill(enter: int, hold: int, leave: int, radius: float, height: float) -> void:
	add_road(enter, hold, leave, TrackHelper.curve_for_radius(radius), height)
