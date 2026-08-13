class_name TrafficProcessor
extends RefCounted

# Car processing and logic

const AVERAGE_PLAYER_SPEED_KMH := 140.0
const FRAME_TIME := 0.12 # TODO: make this distance based instead
const LANE_JITTER := 1.5 # x-axis wiggle room when spawned
const ONCOMING := -1.0
const ONCOMING_LANE := -3.0
const ONCOMING_SPACING := 700.0
const ONCOMING_SPEED_KMH := 35.0
const ONCOMING_SPREAD_KMH := 10.0
const PLACEMENT_JITTER := 40.0 # z-axis wiggle room when spawned
const SAME_WAY := 1.0
const SAME_WAY_LANE := 3.5
const SAME_WAY_SPACING := 350.0
const SAME_WAY_SPEED_KMH := 95.0
const SAME_WAY_SPREAD_KMH := 10.0
const START_CLEARANCE := 250.0 # start spawning far from the end

var list: Array[Car] = []

func spread(track: Track, clear_until := 0.0, oncoming_textures := 1, same_way_textures := 1, side := 1.0) -> void:
	var total := track.get_total_length()
	var start := maxf(START_CLEARANCE, clear_until)

	# ensure we encounter those moving cars while racing
	var race_time := total / TrackHelper.kmh_to_ms(AVERAGE_PLAYER_SPEED_KMH)
	var lead := TrackHelper.kmh_to_ms(ONCOMING_SPEED_KMH) * race_time

	lay_out(start, total + lead, ONCOMING_SPACING, ONCOMING, ONCOMING_LANE * side, ONCOMING_SPEED_KMH, ONCOMING_SPREAD_KMH, oncoming_textures)
	lay_out(start, total, SAME_WAY_SPACING, SAME_WAY, SAME_WAY_LANE * side, SAME_WAY_SPEED_KMH, SAME_WAY_SPREAD_KMH, same_way_textures)

func lay_out(start: float, last: float, spacing: float, direction: float, lane: float, speed_kmh: float, spread_kmh: float, textures: int) -> void:
	var count := maxi(int((last - start) / spacing), 1)
	var step := (last - start) / count

	for i in count:
		var car := Car.new()
		car.direction = direction
		car.x = lane + randf_range(-LANE_JITTER, LANE_JITTER)
		car.z = clampf(start + i * step + randf_range(-PLACEMENT_JITTER, PLACEMENT_JITTER), start, last)
		car.speed = TrackHelper.kmh_to_ms(speed_kmh + randf_range(-1.0, 1.0) * spread_kmh)
		car.frame = randi() % Car.FRAMES if direction < 0.0 else Car.REAR_FRAME
		car.texture_index = randi() % maxi(textures, 1)
		list.append(car)

func update(dt: float) -> void:
	for car in list:
		# no upper clamp: oncoming cars start beyond the finish and drive in
		car.z = maxf(car.z + car.direction * car.speed * dt, 0.0)

		if car.direction < 0.0:
			# TODO: make this distance based
			car.frame_timer -= dt
			if car.frame_timer <= 0.0:
				car.frame_timer = FRAME_TIME
				car.frame = (car.frame + 1) % Car.FRAMES
