class_name PropSolver
extends RefCounted

# Static helper methods to do collisions with props

const ENEMY_HALF_WIDTH := 1.0 # defines horizontal hitbox
const LENGTH_Z := 2.5 # meters of longitudinal overlap
const MIN_SPEED_KMH := 50.0 # no collision below this
const PLAYER_HALF_WIDTH := 0.45 # smaller hitbox for player

static func resolve(bike: PlayerBike, enemies: Array[Enemy], track: Track) -> void:
	var min_speed := TrackHelper.kmh_to_ms(MIN_SPEED_KMH)

	if not bike.is_down() and bike.speed >= min_speed:
		if find_hit(track, bike.x, bike.z, PLAYER_HALF_WIDTH) != null:
			bike.crash()

	for enemy in enemies:
		if enemy.crashed or enemy.speed < min_speed:
			continue
		if find_hit(track, enemy.x, enemy.z, ENEMY_HALF_WIDTH) != null:
			enemy.crash()

static func find_hit(track: Track, x: float, z: float, half_width: float) -> Prop:
	# track uses buckets of N segments for props to prevent having to loop over every object
	var lo := int((z - LENGTH_Z) / Track.HIT_BUCKET)
	var hi := int((z + LENGTH_Z) / Track.HIT_BUCKET)

	# simple rect(x,z) collision detection
	for b in range(lo, hi + 1):
		var bucket: Array = track.crash_buckets.get(b, [])
		for prop in bucket:
			if absf(prop.z - z) > LENGTH_Z:
				continue
			if absf(prop.x - x) < prop.hit_radius + half_width:
				return prop
	return null
