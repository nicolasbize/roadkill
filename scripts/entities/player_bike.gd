class_name PlayerBike
extends RefCounted

# Player entity

enum State {Riding, Attacking, Crashing, Floored, Recovering, Running, Mounting}

const AIR_LOOKAHEAD := 1.0 # m, height
const ATTACK_HIT_FRAME := 1 # the frame where the fist is actually out
const BOOST_MULTIPLIER := 2.0 # 2x acceleration during boost
const BOOST_TIME := 3.0 #s, used for boosting
const GRAVITY := 35.0
const HIT_LIMIT := 3
const HIT_WINDOW := 5.0  # can take up to 3 hits in 5 sec before knockdown
const LEAN_RATE := 5.0 # how fast we lean
const MAX_TRAVEL_RATIO := 2.0 # offroad limits
const OFFROAD_MAX_SPEED_KMH := 60.0
const PUSH_DAMPING := 6.0 # m/s^2 decay on a shove, once clear
const RECOVER_SPEED_KMH := 50.0 # kmh, threshold to assist player in recovery
const RECOVER_STEER := 3.0 # m/s extra push towards road
const RECOVER_TARGET := 0.75 # assist bringing the player back to 75% of line
const RECOVER_TIME := 0.5 # s, time getting off the road
const RUN_BACK_DISTANCE := 5.0 # m, distance to pick up crashed bike
const RUN_SPEED := 3.5 # m/s on foot, backwards
const SLIDE_TIME := 0.3 # slide factor during turns
const START_X := 4.0 # m right of center; the far side from the traffic

var animator := SpriteAnimator.new()
var state := State.Riding
# position and speed
var boost_timer := 0.0
var brake_decel := 14.0
var drag := 0.0
var engine_accel := 12.0
var is_airborne := false
var lean := 0.0
var max_speed := 0.0
var max_speed_kph := 180.0
var max_steer_angle := 0.15
var offroad_resistance := 0.0
var rolling_resistance := 1.5
var speed := 0.0
var steer_input := 0.0  # raw stick this frame, as opposed to the smoothed lean
var vy := 0.0
var x := 0.0
var y := 0.0
var z := 0.0
# attacking
var attack_side := 1.0  # which way you swing; sticks until you steer again
var attack_anim := ""   # which attack is mid-swing, "" when not attacking
var attack_landed := false  # this swing has already connected with someone
var flash_timer := 0.0
var hit_side := 0.0
var hit_timer := 0.0
var push_velocity := 0.0
var recent_hits: Array[float] = []
var weapon_punch_damage := 0
# crashing
var dropped := DroppedBike.new()
var just_crashed := false
var recover_timer := 0.0

func _init(definition: BikeDefinition = null, side := 1.0) -> void:
	if definition != null:
		assert(definition.is_valid(), "%s is not a rideable bike" % definition.resource_path)
		max_steer_angle = definition.max_steer_angle
		max_speed_kph = definition.max_speed_kph
		engine_accel = definition.engine_accel
		brake_decel = definition.brake_decel
		rolling_resistance = definition.rolling_resistance
		weapon_punch_damage = definition.weapon_punch_damage

	max_speed = TrackHelper.kmh_to_ms(max_speed_kph)
	# thrust cancels resistance at max_speed
	drag = (engine_accel - rolling_resistance) / (max_speed * max_speed)
	var offroad_max := TrackHelper.kmh_to_ms(OFFROAD_MAX_SPEED_KMH)
	offroad_resistance = engine_accel - drag * offroad_max * offroad_max
	x = START_X * side

# Anything but riding or swinging: no steering, no contact, no attacks.
func is_down() -> bool:
	return state != State.Riding and state != State.Attacking

# used for camera shake
func check_and_reset_just_crashed() -> bool:
	var was_crashed := just_crashed
	just_crashed = false
	return was_crashed

# true while the fist is out but hasn't hit anything yet.
func is_swinging() -> bool:
	return state == State.Attacking and not attack_landed and animator.frame >= ATTACK_HIT_FRAME

func is_on_foot() -> bool:
	return state == State.Recovering or state == State.Running or state == State.Mounting

func is_offroad() -> bool:
	return absf(x) > TrackHelper.ROAD_HALF_WIDTH

func add_boost() -> void:
	boost_timer = BOOST_TIME

func get_boost_ratio() -> float:
	return boost_timer / BOOST_TIME

func get_speed_ratio() -> float:
	return speed / max_speed

func get_shake_ratio() -> float:
	return absf(get_speed_ratio()) if is_offroad() else 0.0

func update_speed(dt: float, throttle: bool, brake: bool) -> void:
	if state == State.Running:
		speed = -RUN_SPEED
		return
	if state == State.Recovering or state == State.Mounting:
		speed = 0.0
		return

	var resistance := offroad_resistance if is_offroad() else rolling_resistance
	# go newton, go
	var acceleration := -resistance - drag * speed * speed

	if is_down(): # break laws of physics a bit, as we're not considering the mass here
		acceleration -= brake_decel
	else:
		var thrust := engine_accel if throttle else 0.0
		if boost_timer > 0.0:
			thrust = engine_accel * BOOST_MULTIPLIER
		if brake: #TODO: should brake cancel the boost?
			acceleration -= brake_decel
		acceleration += thrust

	speed = clampf(speed + acceleration * dt, 0.0, max_speed)

func update_steering(dt: float, steer: float, curvature: float) -> void:
	steer_input = steer
	if is_on_foot():
		lean = 0.0
		return

	push_velocity = move_toward(push_velocity, 0.0, PUSH_DAMPING * dt)
	x += push_velocity * dt

	# slide towards outside of a curve
	x -= SLIDE_TIME * curvature * speed * speed * dt
	# accoun for player steering
	lean = move_toward(lean, steer, LEAN_RATE * dt)
	x += lean * max_steer_angle * speed * dt
	
	# play screeching sound when leaning hard with med+ speed
	if abs(lean) == 1.0 and speed > max_speed / 2:
		GameEvents.screeched.emit()

	# prevent going too far offroad
	var limit := TrackHelper.ROAD_HALF_WIDTH * MAX_TRAVEL_RATIO
	x = clampf(x, -limit, limit)
	
	apply_recovery(dt)

func update_animation(dt: float) -> void:
	hit_timer = maxf(hit_timer - dt, 0.0)
	flash_timer = maxf(flash_timer - dt, 0.0)
	boost_timer = maxf(boost_timer - dt, 0.0)
	# remove old hits
	for i in range(recent_hits.size() - 1, -1, -1):
		recent_hits[i] -= dt
		if recent_hits[i] <= 0.0:
			recent_hits.remove_at(i)

	match state:
		State.Riding:
			var ratio := get_speed_ratio()
			var anim := BikeSprites.get_riding_anim(ratio, lean)
			animator.speed_scale = BikeSprites.get_ride_scale(ratio)
			animator.play(anim)
			animator.flip_h = BikeSprites.should_mirror(anim, lean)
		State.Attacking:
			animator.speed_scale = 1.0
			animator.play(attack_anim)
		State.Crashing:
			animator.speed_scale = 1.0
			if animator.play("crash"):
				animator.flip_h = false
		State.Floored:
			animator.speed_scale = 1.0
			animator.play("floored")
		State.Recovering:
			animator.speed_scale = 1.0
			if animator.play("recover"):
				animator.flip_h = false
		State.Running:
			animator.speed_scale = 1.0
			animator.play("running")
		State.Mounting:
			animator.speed_scale = 1.0
			animator.play("mounting")

	animator.advance(dt)
	if animator.just_finished:
		on_action_finished(animator.anim)

func apply_recovery(dt: float) -> void:
	var recover_speed := TrackHelper.kmh_to_ms(RECOVER_SPEED_KMH)
	if speed >= recover_speed:
		return
	var target := TrackHelper.ROAD_HALF_WIDTH * RECOVER_TARGET
	if absf(x) <= target:
		return
	var assist := RECOVER_STEER * (1.0 - speed / recover_speed)
	x = move_toward(x, signf(x) * target, assist * dt)

func update_recovery(dt: float, track: Track) -> void:
	match state:
		State.Floored:
			# stay down until the skid has actually stopped, then spawn the
			# bike back down a few meters behind for the rider to walk to
			if speed <= 0.0:
				dropped.place(x, track.get_track_z(z - RUN_BACK_DISTANCE))
				recover_timer = RECOVER_TIME
				state = State.Recovering
		State.Recovering:
			recover_timer -= dt
			if recover_timer <= 0.0:
				state = State.Running
		State.Running:
			if track.gap_z(dropped.z, z) >= 0.0: # mount once we get to the bike
				dropped.clear()
				state = State.Mounting
		_:
			pass

func update_air(dt: float, track: Track) -> void:
	var h := AIR_LOOKAHEAD
	var road_y := track.get_elevation_at(z)

	if not is_airborne:
		# condition to go airborne is to have the road drop down faster than gravity can pull the bike down
		# bend is 2nd derivate of road elevation 
		var bend := (track.get_elevation_at(z + h) - 2.0 * road_y + track.get_elevation_at(z - h)) / (h * h)
		# bend * speed^2 is vertical accel the bike needs to stay on the road
		if bend * speed * speed >= -GRAVITY:
			y = road_y
			vy = 0.0
			return
		is_airborne = true
		y = road_y
		# calculate new vertical velocity
		vy = (track.get_elevation_at(z + h) - track.get_elevation_at(z - h)) / (2.0 * h) * speed

	vy -= GRAVITY * dt
	y += vy * dt
	if y <= road_y:
		y = road_y
		vy = 0.0
		is_airborne = false

func get_air_height() -> float:
	return maxf(y - 0.0, 0.0)

# direction to swing in, 0 when nobody in reach.
func start_attack(anim: String, direction := 0.0) -> void:
	state = State.Attacking
	attack_anim = anim
	attack_landed = false

	if direction != 0.0:
		attack_side = direction
	else:
		# nobody in reach, steering picks the side
		attack_side = signf(steer_input)

	animator.play(anim)
	animator.restart()
	animator.flip_h = attack_side < 0.0
	
func crash() -> void:
	state = State.Crashing
	just_crashed = true
	recent_hits.clear()
	GameEvents.crashed.emit()

func take_hit() -> void:
	if is_down():
		return
	recent_hits.append(HIT_WINDOW)
	#TODO: probably need a visual indicator to indicate we're close to the limit
	if recent_hits.size() >= HIT_LIMIT:
		crash()

func get_hit_pressure() -> float:
	return float(recent_hits.size()) / float(HIT_LIMIT - 1)

func on_action_finished(anim: String) -> void:
	match anim:
		"crash":
			state = State.Floored     # the skid carries on without us
		"mounting":
			state = State.Riding
		_:
			if anim == attack_anim:
				attack_anim = ""
				state = State.Riding
