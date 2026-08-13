class_name WindStreaks
extends RefCounted

# particles emitted to emulate wind when going fast
# these are simple small lines that travel towards the camera pane

const BOOST_COLOR := Color("ffec27")
const COUNT := 14
const FAR := 14.0 # m, clipped after
const FULL_SPEED_KMH := 180.0 # used with MIN_SPEED_KMH to lerp intensity
const MIN_HEIGHT := 0.3 # m above the road
const MIN_SPEED_KMH := 90.0 # nothing shows below this
const MAX_ALPHA := 0.35 # transparency, note this breaks the palette
const MAX_HEIGHT := 6.5 #
const NEAR := 2.5 # m, clipped under
const STREAK_TIME := 0.035 # s of travel
const SPREAD_X := 12.0 # m

var points := PackedVector3Array()   # x, height, distance

func _init() -> void:
	points.resize(COUNT)
	for i in COUNT:
		points[i] = respawn(randf_range(NEAR, FAR))

func respawn(distance: float) -> Vector3:
	return Vector3(randf_range(-SPREAD_X, SPREAD_X), randf_range(MIN_HEIGHT, MAX_HEIGHT), distance)

func update(dt: float, speed: float) -> void:
	var travel := speed * dt
	for i in COUNT:
		var p := points[i]
		p.z -= travel
		if p.z < NEAR:
			p = respawn(FAR)
		points[i] = p

func get_strength(speed: float) -> float:
	var lo := TrackHelper.kmh_to_ms(MIN_SPEED_KMH)
	var hi := TrackHelper.kmh_to_ms(FULL_SPEED_KMH)
	return clampf((speed - lo) / maxf(hi - lo, 0.001), 0.0, 1.0)

func draw(canvas: CanvasItem, camera: RoadCamera, speed: float, boost := 0.0) -> void:
	var strength := maxf(get_strength(speed), boost * 0.8)
	if strength <= 0.0:
		return

	var color := Color.WHITE.lerp(BOOST_COLOR, boost)
	color.a = MAX_ALPHA * strength
	var behind := speed * STREAK_TIME
	var ground := camera.y - RoadCamera.HEIGHT

	for i in COUNT:
		var p := points[i]
		var near_point := Vector2(camera.project_x(p.x, p.z), camera.project_y(ground + p.y, p.z))
		var far := p.z + behind
		var far_point := Vector2(camera.project_x(p.x, far), camera.project_y(ground + p.y, far))

		# don't show single pixels
		if near_point.distance_squared_to(far_point) < 2.0:
			continue
		canvas.draw_line(far_point, near_point, color, 1.0)
