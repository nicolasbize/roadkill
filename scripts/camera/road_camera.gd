class_name RoadCamera
extends RefCounted

# projects view into a 1x1m projection pane in the air the player peeks through

const VIEWPORT_WIDTH := 64.0
const VIEWPORT_HEIGHT := 64.0
const HORIZON_HEIGHT := 31.0
const FIELD_OF_VIEW := 100.0 # bigger widens road and increases impression of speed
const HEIGHT := 3.5 # m off the ground of the proj pane
const BIKE_SCREEN_Y := 63.0 # bike 1 pixel above window bottom
const FOLLOW_LAG := 0.15 # s, smoothens camera movement
const FOV_SPEED_GAIN := 10.0 # degrees added at full speed
const MAX_SPEED_RATIO := 1.3

var x := 0.0
var y := 0.0
var z := 0.0
var shake := Vector2.ZERO # px, screen shake is added after projection

var depth := 0.0 # distance from the eye to the projection plane
var bike_scale := 0.0 # projection scale of the player's bike
var bike_distance := 0.0 # m, from eye to the player's bike
 
func _init() -> void:
	# distance from eye to the projection plane, calculate based on FOV
	# fov 100deg => dist = cotan(50 deg)
	depth = 1.0 / tan(deg_to_rad(FIELD_OF_VIEW / 2.0))
	bike_scale = (BIKE_SCREEN_Y - HORIZON_HEIGHT) / (HEIGHT * VIEWPORT_HEIGHT / 2.0)
	bike_distance = depth / bike_scale
 
func move_to(new_z: float, track: Track) -> void:
	z = maxf(new_z, 0.0)
	update_elevation(track)
 
func follow(target_x: float, dt: float) -> void:
	x = lerpf(x, target_x, minf(dt / FOLLOW_LAG, 1.0))
 
func update_elevation(track: Track) -> void:
	y = track.get_elevation_at(z) + HEIGHT

# increase fov with speed to increase perception of speed
func update_fov(speed_ratio: float) -> void:
	var ratio := clampf(speed_ratio, 0.0, MAX_SPEED_RATIO)
	var fov := FIELD_OF_VIEW + FOV_SPEED_GAIN * ratio
	depth = 1.0 / tan(deg_to_rad(fov / 2.0))
	bike_distance = depth / bike_scale

# Which z segment the camera is on
func get_segment_index() -> int:
	return int(floor(z / TrackHelper.ROAD_SEGMENT_LENGTH))

# z remainder for smooth camera movement alongside z axis
func get_segment_offset() -> float:
	return fposmod(z, TrackHelper.ROAD_SEGMENT_LENGTH)

func get_scale(distance: float) -> float:
	return depth / distance
 
# Screen Y of a point at world_y meters high and z distance ahead
func project_y(world_y: float, distance: float) -> float:
	var plane_y := get_scale(distance) * (y - world_y)
	# grounded items always land below the horizon line
	return HORIZON_HEIGHT + plane_y * VIEWPORT_HEIGHT / 2.0 + shake.y
 
# Screen X of a point world_x meters from center and z distance ahead
func project_x(world_x: float, distance: float) -> float:
	var plane_x := get_scale(distance) * (world_x - x)
	return VIEWPORT_WIDTH / 2.0 + plane_x * VIEWPORT_WIDTH / 2.0 + shake.x
 
# How tall in meters a sprite must be to render in px high at the bike's
# distance. Used to size the enemy sprites so they match the player exactly
func get_world_height_for_pixels(pixels: float) -> float:
	return pixels / (bike_scale * VIEWPORT_HEIGHT / 2.0)
 
