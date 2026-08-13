class_name ScreenShake
extends RefCounted

# very basic screenshake effect, used by camera for takedowns

const MAX_OFFSET := 3.0 # px
const DECAY := 2.5 # px/s 
const FREQUENCY_X := 17.0 # sin factor on the x axis
const FREQUENCY_Y := 23.0 # sin factor on the y axis, slightly different on purpose

var offset := Vector2.ZERO
var rumble := 0.0
var strength := 0.0
var time := 0.0

func add(amount: float) -> void:
	strength = minf(strength + amount, 1.0) # cap it to avoid seizures...

func set_rumble(amount: float) -> void:
	rumble = clampf(amount, 0.0, 1.0)

func update(dt: float) -> void:
	strength = maxf(strength - DECAY * dt, 0.0)
	var level := maxf(strength, rumble)
	if level <= 0.0: # done, reset camera
		offset = Vector2.ZERO
		time = 0.0
		return

	time += dt
	var reach := MAX_OFFSET * level
	var offset_x := roundf(sin(time * TAU * FREQUENCY_X) * reach)
	var offset_y := roundf(sin(time * TAU * FREQUENCY_Y) * reach)
	offset = Vector2(offset_x, offset_y)
