class_name EnemyProcessor
extends RefCounted

# Enemy logic and processing. 
# two states: either engaged in combat or just free riding (engage_side == 0)

const BASE_SPEED_KMH := 140.0
const MAX_SPEED_KMH := 180.0
const ENGINE_ACCEL := 12.0
const WRECK_DECEL := 15.5
const SPEED_SPREAD_KMH := 25.0 # increase this for hard mode
const LOOKAHEAD_TIME := 1.5 # s to anticipate corner
const LOOKAHEAD := 25.0 # m to anticipate obstacles
const STEER_RATE := 2.5 # m/s sideways
const STEER_ANGLE := 0.15
const AVOID_WIDTH := 1.8 # m
const THINK_INTERVAL := Vector2(1.0, 3.0) # s b/w lane changes
const SPAWN_START := 40.0 # m start in front (z) of the player
const SPAWN_SPACING := 30.0 # m distance between each enemy
const LEAN_DISTANCE := 2.0 # m of lane change for full leaning
const LANE_RANGE := 0.7 # % of lane they aim for when swithcing
const SPAWN_INSIDE := 0.15 # stay between 15% and 75% of lane
const SPAWN_OUTSIDE := 0.75
const AVOID_LIMIT := 0.85 # virtual edge at 85% of lane
const RESPAWN_BEHIND := 150.0 # m respawn behind player

# Fighting back
const ATTACK_COOLDOWN := Vector2(2.0, 4.0) # s between hits
const ATTACK_CHANCE := 0.45 # % chance to attack
const ATTACK_REACH := 3.0 # m

# Engagement
const MAX_ENGAGED := 2
const ENGAGE_SPEED_WINDOW_KMH := 40.0 # will engage within 40kmh
const ENGAGE_RANGE_Z := 30.0 # m, accel or decel to engage
const DISENGAGE_RANGE_Z := 45.0
const ENGAGE_OFFSET := 2.3 # m apart
const ENGAGE_ACCEL := 20.0 # m/s^2, overrides default to engage faster
const CLOSE_GAIN := 2.5 # means to catch up when close by
const CLOSE_SPEED_LIMIT := 8.0 # m/s

# Yielding
const YIELD_RANGE_Z := 25.0 # m of run-up to soften speed diff when being engaged
const YIELD_BOOST_KMH := 35.0

# Traffic
const CAR_REACTION_TIME := 2.0 # s of warning
const CAR_CORRIDOR := 4.5 # m, width of oncoming car to react in
const CAR_CLEARANCE := 5.0 # m, target aim relative to car
const CAR_DODGE_RATE := 6.0 # swerve

var list: Array[Enemy] = []
var engage_window := 0.0 # ENGAGE_SPEED_WINDOW_KMH in m/s
var yield_boost := 0.0 # YIELD_BOOST_KMH in m/s
var takedowns := 0 # track elims for unlocks

func _init() -> void:
	engage_window = TrackHelper.kmh_to_ms(ENGAGE_SPEED_WINDOW_KMH)
	yield_boost = TrackHelper.kmh_to_ms(YIELD_BOOST_KMH)

func spawn(count: int, track: Track, bike_z: float, nb_textures: int, side := 1.0) -> void:
	for i in count:
		var enemy := Enemy.new()
		enemy.z = SPAWN_START + i * SPAWN_SPACING
		# spawn on the correct side of the road to prevent collision on start
		enemy.x = side * randf_range(TrackHelper.ROAD_HALF_WIDTH * SPAWN_INSIDE, TrackHelper.ROAD_HALF_WIDTH * SPAWN_OUTSIDE)
		enemy.target_x = enemy.x
		enemy.think_timer = randf_range(THINK_INTERVAL.x, THINK_INTERVAL.y)
		# spawn with initial speed already
		enemy.cruising_speed = TrackHelper.kmh_to_ms(BASE_SPEED_KMH + randf_range(-1.0, 1.0) * SPEED_SPREAD_KMH)
		enemy.speed = enemy.cruising_speed
		enemy.previous_gap_z = track.gap_z(enemy.z, bike_z)
		enemy.texture_index = randi_range(0, nb_textures - 1) # random enemy bike color
		list.append(enemy)

func update(dt: float, track: Track, bike: PlayerBike, cars: Array[Car]) -> void:
	update_engagement(track, bike)

	for enemy in list:
		enemy.hit_timer = maxf(enemy.hit_timer - dt, 0.0)
		enemy.flash_timer = maxf(enemy.flash_timer - dt, 0.0)
		enemy.player_contact_timer = maxf(enemy.player_contact_timer - dt, 0.0)
		enemy.steer_rate = STEER_RATE
		if enemy.crashed:
			update_wreck(dt, enemy)
		else:
			if enemy.engage_side == 0: # free riding
				update_speed(dt, enemy, track, bike)
				pick_target(dt, enemy, track, cars)
			else: # engage with player
				hold_station(dt, enemy, track, bike)
				update_attack(dt, enemy, track, bike)

			# only steer if not stunned
			if enemy.hit_timer <= 0.0:
				apply_steering(dt, enemy)

		update_animation(dt, enemy)
		enemy.z = track.get_track_z(enemy.z + enemy.speed * dt)

	respawn_wrecks(track, bike.z)

# when wrecked, slide until stop
func update_wreck(dt: float, enemy: Enemy) -> void:
	var decel := WRECK_DECEL
	enemy.speed = maxf(enemy.speed - decel * dt, 0.0)

func respawn_wrecks(track: Track, bike_z: float) -> void:
	for enemy in list:
		if not enemy.crashed or enemy.speed > 0.0:
			continue
		takedowns += 1 # TODO: count this when enemy starts crashing instead
		enemy.revive()
		enemy.z = maxf(bike_z - RESPAWN_BEHIND, 0.0)
		enemy.previous_gap_z = track.gap_z(enemy.z, bike_z)
		enemy.think_timer = randf_range(THINK_INTERVAL.x, THINK_INTERVAL.y)

func can_engage(enemy: Enemy, track: Track, bike: PlayerBike, reach: float) -> bool:
	if bike.is_down() or enemy.crashed:
		return false
	if absf(bike.speed - enemy.cruising_speed) > engage_window:
		return false
	return absf(track.gap_z(enemy.z, bike.z)) <= reach

# check who should enegage the player
func update_engagement(track: Track, bike: PlayerBike) -> void:
	var taken := {}   # only two hotel slots available

	# keep those already engaged if possible
	for enemy in list:
		if enemy.engage_side == 0:
			continue
		if taken.has(enemy.engage_side) or not can_engage(enemy, track, bike, DISENGAGE_RANGE_Z):
			disengage(enemy)
		else:
			taken[enemy.engage_side] = enemy

	if taken.size() >= MAX_ENGAGED:
		return

	# find remaining candidates
	var candidates: Array[Enemy] = []
	for enemy in list:
		if enemy.engage_side == 0 and can_engage(enemy, track, bike, ENGAGE_RANGE_Z):
			candidates.append(enemy)
	candidates.sort_custom(func(a, b):
		return absf(track.gap_z(a.z, bike.z)) < absf(track.gap_z(b.z, bike.z)))

	for enemy in candidates:
		if taken.size() >= MAX_ENGAGED:
			break
		# default to side they're on, otherwise take the other one
		var side := 1 if enemy.x >= bike.x else -1
		if taken.has(side):
			side = -side
		if taken.has(side):
			break
		enemy.engage_side = side
		taken[side] = enemy

func disengage(enemy: Enemy) -> void:
	enemy.engage_side = 0
	enemy.think_timer = 0.0 # change lane right away

# try to keep up with player for easier engagement
func hold_station(dt: float, enemy: Enemy, track: Track, bike: PlayerBike) -> void:
	var gap_z := track.gap_z(enemy.z, bike.z)
	var closing := clampf(-gap_z * CLOSE_GAIN, -CLOSE_SPEED_LIMIT, CLOSE_SPEED_LIMIT)
	# limit how much they can keep up
	var ceiling := bike.speed + CLOSE_SPEED_LIMIT
	var target := clampf(bike.speed + closing, 0.0, ceiling)
	var edge := TrackHelper.ROAD_HALF_WIDTH
	enemy.speed = move_toward(enemy.speed, target, ENGAGE_ACCEL * dt)
	enemy.target_x = clampf(bike.x + enemy.engage_side * ENGAGE_OFFSET, -edge, edge)

func update_attack(dt: float, enemy: Enemy, track: Track, bike: PlayerBike) -> void:
	enemy.attack_cooldown = maxf(enemy.attack_cooldown - dt, 0.0)

	if enemy.attack_anim != "":
		return                       # already mid-swing
	if enemy.engage_side == 0 or bike.is_down() or enemy.hit_timer > 0.0:
		return
	if enemy.attack_cooldown > 0.0:
		return
	if absf(track.gap_z(enemy.z, bike.z)) > CombatSolver.REACH_LENGTH:
		return
	if absf(bike.x - enemy.x) > ATTACK_REACH:
		return

	# The cooldown restarts whether or not they take the shot, so declining
	# costs them the same wait. Without that they would retry every frame
	# and the chance would do nothing.
	enemy.attack_cooldown = randf_range(ATTACK_COOLDOWN.x, ATTACK_COOLDOWN.y)
	if randf() > ATTACK_CHANCE:
		return

	# try to punch 
	enemy.attack_anim = "punch"
	enemy.attack_side = signf(bike.x - enemy.x)
	enemy.attack_landed = false # depends on actual distance
	enemy.animator.play(enemy.attack_anim)
	enemy.animator.flip_h = enemy.attack_side < 0.0

# free driving
func update_speed(dt: float, enemy: Enemy, track: Track, bike: PlayerBike) -> void:
	var ahead := enemy.z + enemy.speed * LOOKAHEAD_TIME
	var curvature := absf(track.get_curvature_at(ahead))

	# slow down for corners
	var limit := enemy.cruising_speed
	if curvature > 0.0001:
		limit = minf(limit, STEER_ANGLE / (PlayerBike.SLIDE_TIME * curvature))

	# override when about to get engaged by player
	limit = maxf(limit, get_yield_speed(enemy, bike, track))
	enemy.speed = move_toward(enemy.speed, limit, ENGINE_ACCEL * dt)

# converge towards player speed when they are closing in fast, to smoothen out engagement
func get_yield_speed(enemy: Enemy, bike: PlayerBike, track: Track) -> float:
	var gap_z := track.gap_z(enemy.z, bike.z)
	if gap_z <= 0.0 or gap_z > YIELD_RANGE_Z:
		return 0.0 # too far off, ignore
	if bike.speed <= enemy.speed:
		return 0.0 # not catching up, ignore

	# lerp the speed for smoother engagement
	var urgency := 1.0 - gap_z / YIELD_RANGE_Z
	var ceiling := enemy.cruising_speed + yield_boost
	return lerpf(enemy.cruising_speed, minf(bike.speed, ceiling), urgency)

# pick X location to go towards
func pick_target(dt: float, enemy: Enemy, track: Track, cars: Array[Car]) -> void:
	var edge := TrackHelper.ROAD_HALF_WIDTH * AVOID_LIMIT

	# pick a new default target x lane after some time
	enemy.think_timer -= dt
	if enemy.think_timer <= 0.0:
		enemy.think_timer = randf_range(THINK_INTERVAL.x, THINK_INTERVAL.y)
		var max_target_x := TrackHelper.ROAD_HALF_WIDTH * LANE_RANGE
		enemy.target_x = randf_range(-max_target_x, max_target_x)

	# override target_x to swerve around other enemies
	for obstacle in list:
		if obstacle == enemy: # ignore self
			continue
		var gap_z := track.gap_z(obstacle.z, enemy.z)
		if gap_z > 0.0 and gap_z < LOOKAHEAD and absf(obstacle.x - enemy.x) < AVOID_WIDTH:
			var side := 1.0 if enemy.x >= obstacle.x else -1.0
			enemy.target_x = clampf(obstacle.x + side * AVOID_WIDTH * 2.0, -edge, edge)
			break

	# override target_x to swerve around trafic
	for car in cars:
		var car_gap_z := track.gap_z(car.z, enemy.z)
		if car_gap_z <= 0.0:
			continue # car passed enemy
		var closing := enemy.speed - car.direction * car.speed
		if closing <= 0.0 or car_gap_z > closing * CAR_REACTION_TIME:
			continue # car too far in front
		if absf(car.x - enemy.x) > CAR_CORRIDOR:
			continue # no need to swerve
		# go round whichever side they are already nearer to
		var side := 1.0 if enemy.x >= car.x else -1.0
		enemy.target_x = clampf(car.x + side * CAR_CLEARANCE, -edge, edge)
		enemy.steer_rate = CAR_DODGE_RATE
		break

func apply_steering(dt: float, enemy: Enemy) -> void:
	# lean into whichever way they still have to travel
	var wanted := clampf((enemy.target_x - enemy.x) / LEAN_DISTANCE, -1.0, 1.0)
	enemy.lean = move_toward(enemy.lean, wanted, PlayerBike.LEAN_RATE * dt)
	enemy.x = move_toward(enemy.x, enemy.target_x, enemy.steer_rate * dt)

func update_animation(dt: float, enemy: Enemy) -> void:
	if enemy.crashed:
		enemy.animator.speed_scale = 1.0
		if enemy.animator.play("crash"):
			enemy.animator.flip_h = false
	elif enemy.attack_anim != "":
		enemy.animator.speed_scale = 1.0
		enemy.animator.play(enemy.attack_anim)
	elif enemy.hit_timer > 0.0:
		# when hit, hold specific lean anim
		enemy.animator.speed_scale = 1.0
		enemy.animator.play("lean_%d" % enemy.hit_lean)
		enemy.animator.flip_h = enemy.hit_side < 0.0
	else:
		# speed of anim scales with speed
		var ratio := enemy.speed / TrackHelper.kmh_to_ms(MAX_SPEED_KMH)
		var anim := BikeSprites.get_riding_anim(ratio, enemy.lean)
		enemy.animator.speed_scale = BikeSprites.get_ride_scale(ratio)
		enemy.animator.play(anim)
		enemy.animator.flip_h = BikeSprites.should_mirror(anim, enemy.lean)

	enemy.animator.advance(dt)
	if enemy.animator.just_finished and enemy.animator.anim == enemy.attack_anim:
		enemy.attack_anim = ""
		
# how far we spawn the pack, used to spawn cars even further
func get_furthest_z() -> float:
	var furthest := 0.0
	for enemy in list:
		furthest = maxf(furthest, enemy.z)
	return furthest
