class_name Enemy
extends RefCounted

const MAX_HEALTH := 10

# main properties
var animator := SpriteAnimator.new()
var texture_index := 0
var think_timer := 0.0 # timer for decision making
var tint := Color.WHITE # TODO: can clean this up
# position / speed
var cruising_speed := 0.0 # m/s - default speed
var lean := 0.0 # -1 for hard left, +1 for hard right
var previous_gap_z := 0.0 # m. last frame's signed distance from the player
var speed := 0.0 # m/s
var steer_rate := 0.0 # m/s sideways, increased to dodge traffic
var target_x := 0.0 # m
var x := 0.0 # m
var z := 0.0 # m
# getting hit/bumped
var bump_timer := 0.0 # s. ratelimit bumping contacts
var crashed := false
var engage_side := 0 # which side to engage in (-1 left, +1 right, 0 free)
var flash_timer := 0.0 # s. time showing flash impact sprite
var health := MAX_HEALTH
var hit_lean := 1 # frame to hold when stunned
var hit_side := 0.0 # -1 left, 1 right
var hit_timer := 0.0 # s. time being stunned
var just_crashed := false
var player_contact_timer := 0.0 # s. time since player bumped the enemy
var push_velocity := 0.0
# attacks
var attack_anim := ""
var attack_cooldown := 0.0
var attack_landed := false
var attack_side := 1.0

func take_damage(amount: int) -> void:
	if crashed:
		return
	health = maxi(health - amount, 0)
	if health == 0:
		crash()

# used for camera shake
func check_and_reset_just_crashed() -> bool:
	var was_crashed := just_crashed
	just_crashed = false
	return was_crashed

# don't reset knockback so they slide when crashing
func crash() -> void:
	crashed = true
	health = 0
	engage_side = 0
	hit_timer = 0.0
	just_crashed = true
	GameEvents.crashed.emit()

func revive() -> void:
	crashed = false
	just_crashed = false
	health = MAX_HEALTH
	x = 0.0
	target_x = 0.0
	lean = 0.0
	speed = cruising_speed
	engage_side = 0
	hit_timer = 0.0
	flash_timer = 0.0
	bump_timer = 0.0
	push_velocity = 0.0
	player_contact_timer = 0.0
	attack_anim = ""
	attack_landed = false
	attack_cooldown = 0.0
