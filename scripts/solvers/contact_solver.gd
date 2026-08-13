class_name ContactSolver
extends RefCounted

# static helper methods to do manual collision detection

const BIKE_LENGTH := 2.6 # m. for front/back collisions
const BIKE_WIDTH := 2.1 # m. for lateral collsions
const BLOCK_DECEL := 40.0 # m/s^2 decel when tailgating
const BUMP_COOLDOWN := 0.3
const CONTACT_TIMER := 1.0 # 1s cooldown
const CRASH_CLOSING_SPEED := 14.0  # m/s, ~50kmh difference results in crash
const MAX_PUSH_SPEED := 3.0 # m/s
const PLAYER_SHARE := 0.5 # how much % of pushback the player takes during common grind/pushback
const PUSH_ACCEL := 16.0 # m/s^2 of shove at full overlap, for feel
const RAM_ACCEL := 6.0 # m/s^2 decel when rammed into
const REAR_END_SPEED_LOSS := 0.9 # m/s^2 decel when reraended
const SEPARATION_RATE := 12.0 # m/s of non overlapping
const SCRUB := 4.0 # m/s^2 decel while grinding

# check if enemy bike went through player bike position on the z axis
static func passed_through(gap_z: float, previous_gap_z: float) -> bool:
	return absf(gap_z) > BIKE_LENGTH and signf(gap_z) != signf(previous_gap_z)

# collision detection between player and enemies
static func resolve(dt: float, bike: PlayerBike, enemies: Array[Enemy], track: Track) -> void:
	for enemy in enemies:
		var gap_z := track.gap_z(enemy.z, bike.z)
		var prev_z := enemy.previous_gap_z
		enemy.previous_gap_z = gap_z
		enemy.bump_timer = maxf(enemy.bump_timer - dt, 0.0)
		enemy.push_velocity = move_toward(enemy.push_velocity, 0.0, PlayerBike.PUSH_DAMPING * dt)
		enemy.x += enemy.push_velocity * dt

		# bypass crashed bike.
		# TODO: in road rash the player rolls over crashed enemies and bops over it a bit
		#      pretty satisfying mechanic worth considering here as well
		if bike.is_down() or enemy.crashed:
			continue

		# too much distance
		var lateral := enemy.x - bike.x
		var x_overlap := BIKE_WIDTH - absf(lateral)
		if x_overlap <= 0.0:
			continue

		# if passed through on z axis within proper distance, treat it as a collision
		var z_overlap := BIKE_LENGTH - absf(gap_z)
		if passed_through(gap_z, prev_z):
			z_overlap = BIKE_LENGTH
			gap_z = prev_z
		if z_overlap <= 0.0:
			continue

		# push aside or block depending on whether the collision is sideways or vertical
		if x_overlap / BIKE_WIDTH <= z_overlap / BIKE_LENGTH:
			push_apart(dt, bike, enemy, lateral, x_overlap)
		else:
			block(dt, bike, enemy, track, gap_z, z_overlap)

# push two bikes apart
static func push_apart(dt: float, bike: PlayerBike, enemy: Enemy, lateral: float, overlap: float) -> void:
	enemy.player_contact_timer = CONTACT_TIMER
	var side := signf(lateral)
	if side == 0.0:
		side = 1.0

	# insta-push both bikes sideways
	var correction := minf(overlap, SEPARATION_RATE * dt)
	bike.x -= side * correction * PLAYER_SHARE
	enemy.x += side * correction * (1.0 - PLAYER_SHARE)
	enemy.target_x = enemy.x # enemy needs to stop going into the player after colliding

	# keep some momentum to push them over time
	var depth := overlap / BIKE_WIDTH
	var enemy_limit := maxf(MAX_PUSH_SPEED, absf(enemy.push_velocity))
	var bike_limit := maxf(MAX_PUSH_SPEED, absf(bike.push_velocity))
	enemy.push_velocity = clampf(enemy.push_velocity + side * PUSH_ACCEL * depth * dt, -enemy_limit, enemy_limit)
	bike.push_velocity = clampf(bike.push_velocity - side * PUSH_ACCEL * depth * dt, -bike_limit, bike_limit)

	# slow both bikes down
	bike.speed = maxf(bike.speed - SCRUB * depth * dt, 0.0)
	enemy.speed = maxf(enemy.speed - SCRUB * depth * dt, 0.0)

# blocking on the z axis 
static func block(dt: float, bike: PlayerBike, enemy: Enemy, track: Track, gap_z: float, overlap: float) -> void:
	enemy.player_contact_timer = CONTACT_TIMER
	var closing := bike.speed - enemy.speed

	# rear-ending hard causes a crash
	if gap_z > 0.0 and closing > CRASH_CLOSING_SPEED and enemy.bump_timer <= 0.0:
		bike.crash()
		enemy.speed *= REAR_END_SPEED_LOSS
		enemy.bump_timer = BUMP_COOLDOWN
		return

	var correction := minf(overlap, SEPARATION_RATE * dt)
	if gap_z > 0.0: # enemy in front
		enemy.z = track.get_track_z(enemy.z + correction)
		if closing > 0.0:
			bike.speed = move_toward(bike.speed, enemy.speed, BLOCK_DECEL * dt)
			enemy.speed = move_toward(enemy.speed, bike.speed, RAM_ACCEL * dt)
	else: # rear-ended
		enemy.z = track.get_track_z(enemy.z - correction)
		if closing < 0.0:
			enemy.speed = move_toward(enemy.speed, bike.speed, BLOCK_DECEL * dt)
