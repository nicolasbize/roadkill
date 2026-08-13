class_name LeanSparks
extends RefCounted

# very basic manual particle effects, can't use GPUParticles2D here

const MAX_PARTICLES := 36
const LEAN_THRESHOLD := 0.75 # only emit when leaning hard
const RATE := 60.0
const LIFE := 0.40
const MIN_SPEED_KMH := 60.0 # min speed for emitting

const GRAVITY := 200.0
const SIDE_SPEED := Vector2(22.0, 55.0) # min/max px/s, emitted away from the bike
const LIFT_SPEED := Vector2(15.0, 45.0) # min/max px/s, emitted upwards
const SPRAY := 1.5 # px for shape emission

const HOT := Color("ffec27")
const COOL := Color("ffa300")

var position := PackedVector2Array()
var velocity := PackedVector2Array()
var life := PackedFloat32Array()
var pending := 0.0

func _init() -> void:
	position.resize(MAX_PARTICLES)
	velocity.resize(MAX_PARTICLES)
	life.resize(MAX_PARTICLES)

func update(dt: float, bike: PlayerBike, camera: RoadCamera) -> void:
	# move each particle
	for i in MAX_PARTICLES:
		if life[i] <= 0.0:
			continue
		life[i] -= dt
		var v := velocity[i]
		v.y += GRAVITY * dt
		velocity[i] = v
		position[i] += v * dt

	emit(dt, bike, camera)

func emit(dt: float, bike: PlayerBike, camera: RoadCamera) -> void:
	# don't emit when crashed, airborne, too slow or not leaned enough
	if bike.is_down() or bike.is_airborne:
		pending = 0.0
		return
	if bike.speed < TrackHelper.kmh_to_ms(MIN_SPEED_KMH):
		pending = 0.0
		return
	var lean := absf(bike.lean)
	if lean < LEAN_THRESHOLD:
		pending = 0.0
		return

	var strength := clampf((lean - LEAN_THRESHOLD) / (1.0 - LEAN_THRESHOLD), 0.0, 1.0)
	var side := -signf(bike.lean)

	# emit from the tire, not the bike position
	var anim := bike.animator.anim
	var anchor_x := camera.project_x(bike.x, camera.bike_distance) + BikeSprites.get_shadow_offset(anim, bike.animator.flip_h)
	var anchor_y := camera.project_y(bike.y, camera.bike_distance)
	var anchor := Vector2(anchor_x, anchor_y)
	pending += RATE * strength * dt
	while pending >= 1.0:
		pending -= 1.0
		spawn(anchor, side)

func spawn(anchor: Vector2, side: float) -> void:
	var i := find_free()
	if i < 0:
		return
	position[i] = anchor + Vector2(randf_range(-SPRAY, SPRAY), randf_range(-SPRAY, 0.0))
	velocity[i] = Vector2(side * randf_range(SIDE_SPEED.x, SIDE_SPEED.y), -randf_range(LIFT_SPEED.x, LIFT_SPEED.y))
	life[i] = LIFE

func find_free() -> int:
	for i in MAX_PARTICLES:
		if life[i] <= 0.0:
			return i
	return -1

func draw(canvas: CanvasItem) -> void:
	for i in MAX_PARTICLES:
		if life[i] <= 0.0:
			continue
		var t := 1.0 - life[i] / LIFE
		# cools as it goes
		var color := HOT.lerp(COOL, t)
		color.a = minf((1.0 - t) * 3.0, 1.0)
		canvas.draw_rect(Rect2(roundf(position[i].x), roundf(position[i].y), 1.0, 1.0), color)
