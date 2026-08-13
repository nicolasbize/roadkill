class_name TrafficSolver
extends RefCounted

# Collision detection with cars

const BLOCK_DECEL := 40.0 # m/s^2 lost while stuck behind car
const CAR_WIDTH := 2.5 # box dims for collision detection
const CAR_LENGTH := 3.5
const CLEARANCE := 1.2 # m past the car enemies aim for
const NUDGE := 0.6 # m/s sideways, so you can pick your way past
const REAR_CRASH_SPEED := 25.0 # m/s: above this diff of speed we crash
const SHOVE := 3.5 # m/s sideways

static func resolve(dt: float, bike: PlayerBike, enemies: Array[Enemy], cars: Array[Car], track: Track) -> void:
	for car in cars:
		if not bike.is_down() and overlaps(car, bike.x, bike.z, track):
			hit_player(dt, bike, car)

		for enemy in enemies:
			if enemy.crashed:
				continue
			if overlaps(car, enemy.x, enemy.z, track):
				hit_enemy(dt, enemy, car)

static func overlaps(car: Car, x: float, z: float, track: Track) -> bool:
	return absf(car.x - x) < CAR_WIDTH and absf(track.gap_z(car.z, z)) < CAR_LENGTH

static func hit_player(dt: float, bike: PlayerBike, car: Car) -> void:
	if car.direction < 0.0:
		bike.crash() # always crash against oncoming traffic
		return

	if bike.speed - car.speed > REAR_CRASH_SPEED:
		bike.crash() # rear-ending too fast crashes as well
		return

	# reduce speed otherwise
	bike.speed = move_toward(bike.speed, car.speed, BLOCK_DECEL * dt)
	var side := signf(bike.x - car.x)
	if side == 0.0:
		side = 1.0
	bike.push_velocity = clampf(bike.push_velocity + side * NUDGE, -ContactSolver.MAX_PUSH_SPEED, ContactSolver.MAX_PUSH_SPEED)

static func hit_enemy(dt: float, enemy: Enemy, car: Car) -> void:
	var closing := enemy.speed - car.direction * car.speed
	# easier for enemies to crash on rear-ending cars
	var lethal := car.direction < 0.0 or closing > REAR_CRASH_SPEED / 2.0

	# only crash when it's caused by the player
	# prevents unnecessary death out of camera view
	if lethal and enemy.player_contact_timer > 0.0:
		enemy.crash()
		return

	var side := signf(enemy.x - car.x)
	if side == 0.0:
		side = 1.0

	enemy.push_velocity = clampf(enemy.push_velocity + side * SHOVE, -maxf(ContactSolver.MAX_PUSH_SPEED, SHOVE), maxf(ContactSolver.MAX_PUSH_SPEED, SHOVE))
	enemy.target_x = clampf(car.x + side * (CAR_WIDTH + CLEARANCE), -TrackHelper.ROAD_HALF_WIDTH, TrackHelper.ROAD_HALF_WIDTH)

	# don't go through ongoing traffic, get stuck until change lines
	if car.direction > 0.0:
		enemy.speed = move_toward(enemy.speed, car.speed, BLOCK_DECEL * dt)
