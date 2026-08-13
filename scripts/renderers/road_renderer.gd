class_name RoadRenderer
extends RefCounted

# Draw the road segments

const DRAW_DISTANCE := 200 # probably overkill unless big downhill + big uphill
const STRIP_COUNT := DRAW_DISTANCE - 1 # segment 0 sits under the camera
const MIN_DRAW_DISTANCE := 0.5 # cull everything closer
const DIRT_BAND_SEGMENTS := 6 # swap scenary bg color every 6m
const ROAD_EDGE_WIDTH := 0.6 # m
const LANE_LINE_HALF_WIDTH := 0.5 # m
const LANE_DASH_SEGMENTS := 3 # 3m paint, 3m gap
const LANE_DETAIL_DISTANCE := 30.0 # m

var theme: RoadTheme 

var strips: Array[Dictionary] = [] # one strip per segment drawn derived from camera position
var strip_offset := 0.0 # how far into the current segment the camera sits

func _init(road_theme: RoadTheme) -> void:
	theme = road_theme
	strips.resize(STRIP_COUNT)
	for i in STRIP_COUNT:
		strips[i] = {"z": 0.0, "x": 0.0, "elevation": 0.0, "clip_y": 0.0}

func draw(canvas: CanvasItem, camera: RoadCamera, track: Track) -> void:
	var base_index := camera.get_segment_index()
	strip_offset = camera.get_segment_offset()
	var clip_y := RoadCamera.VIEWPORT_HEIGHT
	var road_x := 0.0
	var road_dx := 0.0

	# near to far becasue we need to keep track of clipping to render our sprites
	for i in range(1, DRAW_DISTANCE): # 0 is below the camera
		var near_z := i * TrackHelper.ROAD_SEGMENT_LENGTH - strip_offset
		var far_z := near_z + TrackHelper.ROAD_SEGMENT_LENGTH
		var segment_index := base_index + i
		var segment := track.get_segment(segment_index)
		var next_segment := track.get_segment(segment_index + 1)
		var near_x := road_x
		var far_x := road_x + road_dx
		var near_y := roundf(camera.project_y(segment.y, near_z))
		var far_y := roundf(camera.project_y(next_segment.y, far_z))

		road_x += road_dx
		road_dx += segment.curve

		var strip: Dictionary = strips[i - 1]
		strip["z"] = near_z
		strip["x"] = near_x
		strip["elevation"] = segment.y
		strip["clip_y"] = clip_y # allows enemies/props to poke over crests

		if far_y >= clip_y:
			continue

		@warning_ignore("integer_division")
		var is_light := (segment_index / DIRT_BAND_SEGMENTS) % 2 == 0
		var dirt_color := theme.dirt_light if is_light else theme.dirt_dark
		var edge_color := theme.edge_light if is_light else theme.edge_dark
		# dirt first
		canvas.draw_rect(Rect2(0, far_y, RoadCamera.VIEWPORT_WIDTH, maxf(near_y - far_y, 0.0)), dirt_color)
		# wider road first, only edges will remain
		draw_quad(canvas, camera, near_x, near_y, near_z, far_x, far_y, far_z, TrackHelper.ROAD_HALF_WIDTH + ROAD_EDGE_WIDTH, edge_color)
		# normal road
		draw_quad(canvas, camera, near_x, near_y, near_z, far_x, far_y, far_z, TrackHelper.ROAD_HALF_WIDTH, theme.road)
		# road lines
		@warning_ignore("integer_division")
		if near_z < LANE_DETAIL_DISTANCE and (segment_index / LANE_DASH_SEGMENTS) % 2 == 0:
			draw_quad(canvas, camera, near_x, near_y, near_z, far_x, far_y, far_z, LANE_LINE_HALF_WIDTH, theme.lane_line)

		clip_y = far_y

	# when going downhill, if nothing is in the 200m distance then it is empty
	# fill with some haze/fog color.
	var top := RoadCamera.HORIZON_HEIGHT + 1.0 + camera.shake.y
	if clip_y > top:
		canvas.draw_rect(Rect2(0.0, top, RoadCamera.VIEWPORT_WIDTH, clip_y - top), theme.haze)

# draw simple polygon
func draw_quad(canvas: CanvasItem, camera: RoadCamera, near_x: float, near_y: float, near_z: float, far_x: float, far_y: float, far_z: float, half_width: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(camera.project_x(near_x - half_width, near_z), near_y),
		Vector2(camera.project_x(near_x + half_width, near_z), near_y),
		Vector2(camera.project_x(far_x + half_width, far_z), far_y),
		Vector2(camera.project_x(far_x - half_width, far_z), far_y),
	]), color)

func find_strip_index(distance: float) -> int:
	if distance < MIN_DRAW_DISTANCE:
		return -1
	var index := int(floor((distance + strip_offset) / TrackHelper.ROAD_SEGMENT_LENGTH)) - 1
	if index >= STRIP_COUNT:
		return -1
	return maxi(index, 0)

# get road info at specific z distance, used for placing objects on road,
# figure out what gets clipped when being drawn etc.
func get_info(distance: float) -> Dictionary:
	var index := find_strip_index(distance)
	if index < 0:
		return {}
	var strip: Dictionary = strips[index]
	var offset: float = strip.x
	var elevation: float = strip.elevation

	if index < STRIP_COUNT - 1:
		# distance z is somewhere b/w strip and next_strip, interpolate to find offset and elevation/height
		var next_strip: Dictionary = strips[index + 1]
		var span: float = next_strip.z - strip.z
		if span > 0.0:
			var t := clampf((distance - strip.z) / span, 0.0, 1.0)
			offset = lerpf(strip.x, next_strip.x, t)
			elevation = lerpf(strip.elevation, next_strip.elevation, t)
	
	# don't interpolate the clipping, it's picked up from the closest strip
	return {"offset": offset, "elevation": elevation, "clip_y": strip.clip_y}
