class_name Race
extends RefCounted

# The race entity
# 3 possible states: countdown, racing and finished

enum State {Countdown, Racing, Finished}

const NUMBERS := 3
const STEP := 1.0
const DURATION_GO_HOLD := 0.7
const FRAME_GO := 3

var state := State.Countdown
var timer := 0.0
var finish_z := 0.0
var time_since_finish := Time.get_ticks_msec()

func start(track: Track) -> void:
	finish_z = track.finish_z
	state = State.Countdown
	timer = 0.0

func is_moving() -> bool:
	return state != State.Countdown

func is_finished() -> bool:
	return state == State.Finished

func update(dt: float, bike_z: float) -> void:
	timer += dt
	match state:
		State.Countdown:
			if timer >= NUMBERS * STEP:
				state = State.Racing
		State.Racing:
			if bike_z >= finish_z:
				state = State.Finished
				time_since_finish = Time.get_ticks_msec()
		State.Finished:
			if Time.get_ticks_msec() - time_since_finish > 2000:
				GameEvents.race_finished.emit()

func get_countdown_frame() -> int:
	if timer >= NUMBERS * STEP + DURATION_GO_HOLD:
		return -1
	if timer < NUMBERS * STEP:
		return int(timer / STEP) # 0, 1, 2 -> "3", "2", "1"
	return FRAME_GO
