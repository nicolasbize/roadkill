class_name CombatSolver
extends RefCounted

# static methods to process combat logic

const DURATION_FLASH := 0.10
const REACH_LENGTH := 2.0 # m. forward/backward reach
const REACH_SIDE := 3.0 # m. lateral reach

# TODO: should sounds be defined here as well?
const ATTACKS := {
	"punch": {"damage": 3, "knockback": 3.0, "stun": 0.30, "lean": 1},
	"kick":  {"damage": 1, "knockback": 9.5, "stun": 0.85, "lean": 2},
}
const ENEMY_ATTACK := {"knockback": 2.5, "stun": 0.0}
const ENEMY_REACH_SIDE := 2.5 # enemies get baby arms

static func resolve(bike: PlayerBike, enemies: Array[Enemy], track: Track, impacts: Impacts) -> void:
	if not bike.is_swinging():
		return

	var target := find_target(bike, enemies, track)
	if target == null:
		GameEvents.hit_missed.emit()
		return

	bike.attack_landed = true # prevent multiple hits per attack
	land_hit(bike, target, bike.attack_side, get_attack(bike.attack_anim))
	if bike.attack_anim == "punch":
		if bike.weapon_punch_damage > 0:
			GameEvents.clubbed.emit()
		else:
			GameEvents.punched.emit()
	else:
		GameEvents.kicked.emit()
	# show impact visual effect in the middle
	impacts.add(bike.attack_anim, (bike.x + target.x) / 2.0, bike.z)

# find the closest enemy in the direction the biker is swinging
static func find_target(bike: PlayerBike, enemies: Array[Enemy], track: Track) -> Enemy:
	var best: Enemy = null
	var best_distance := REACH_SIDE
	
	for enemy in enemies:
		var lateral := enemy.x - bike.x
		if lateral * bike.attack_side <= 0.0:
			continue # behind
		if absf(lateral) > REACH_SIDE:
			continue # too far to the side
		if enemy.crashed:
			continue # don't be cruel
		if absf(track.gap_z(enemy.z, bike.z)) > REACH_LENGTH:
			continue # too far behind
		if absf(lateral) < best_distance:
			best_distance = absf(lateral)
			best = enemy
	return best

static func get_attack(anim: String) -> Dictionary:
	var attack: Dictionary = ATTACKS.get(anim, "punch")
	return attack

# player hitting enemies
static func land_hit(bike: PlayerBike, enemy: Enemy, side: float, attack: Dictionary) -> void:
	var damage: int = attack.damage
	var knockback: float = attack.knockback
	var lean: int = attack.lean
	
	# using a weapon reuses the punch animation, override the damage
	if bike.weapon_punch_damage > 0 and bike.attack_anim == "punch":
		damage = bike.weapon_punch_damage

	enemy.hit_side = side
	enemy.hit_lean = lean
	
	# knockback
	var limit := maxf(ContactSolver.MAX_PUSH_SPEED, knockback)
	enemy.push_velocity = clampf(enemy.push_velocity + side * knockback, -limit, limit)

	# track time for the sprite flashing
	enemy.hit_timer = attack.stun
	enemy.flash_timer = DURATION_FLASH
	enemy.player_contact_timer = ContactSolver.CONTACT_TIMER
	
	# damage and boost player
	var was_up := not enemy.crashed
	enemy.take_damage(damage)
	if was_up and enemy.crashed:
		bike.add_boost()

# swinging direction depends on which character is closest
# TODO: refactor this with find_target
static func get_aim_side(bike: PlayerBike, enemies: Array[Enemy], track: Track) -> float:
	var nearest := 0.0
	var nearest_gap := REACH_SIDE
	var steered := 0.0
	
	for enemy in enemies:
		var lateral := enemy.x - bike.x
		var side := signf(lateral)
		if enemy.crashed:
			continue
		if absf(track.gap_z(enemy.z, bike.z)) > REACH_LENGTH:
			continue
		if absf(lateral) > REACH_SIDE or is_zero_approx(lateral):
			continue
		# manually leaning overrides autoselction
		if side == signf(bike.steer_input):
			steered = side
		if absf(lateral) < nearest_gap:
			nearest_gap = absf(lateral)
			nearest = side
	return steered if steered != 0.0 else nearest

# TODO: refactor this with player attack
static func resolve_enemy_attacks(bike: PlayerBike, enemies: Array[Enemy], track: Track, impacts: Impacts) -> void:
	if bike.is_down():
		return

	for enemy in enemies:
		if enemy.crashed or enemy.attack_anim == "" or enemy.attack_landed:
			continue
		if enemy.animator.frame < PlayerBike.ATTACK_HIT_FRAME:
			continue

		var lateral := bike.x - enemy.x
		if lateral * enemy.attack_side <= 0.0:
			continue
		if absf(lateral) > ENEMY_REACH_SIDE:
			continue
		if absf(track.gap_z(enemy.z, bike.z)) > REACH_LENGTH:
			continue

		enemy.attack_landed = true
		GameEvents.punched.emit()
		land_player_hit(bike, signf(lateral))
		impacts.add(enemy.attack_anim, (bike.x + enemy.x) / 2.0, bike.z)

# impact the player
static func land_player_hit(bike: PlayerBike, side: float) -> void:
	var knockback: float = ENEMY_ATTACK.knockback
	var limit := maxf(ContactSolver.MAX_PUSH_SPEED, knockback)
	bike.hit_side = side
	bike.push_velocity = clampf(bike.push_velocity + side * knockback, -limit, limit)
	bike.hit_timer = ENEMY_ATTACK.stun
	bike.flash_timer = DURATION_FLASH
	bike.take_hit()
