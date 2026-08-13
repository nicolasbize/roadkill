class_name SpriteAnimator
extends RefCounted

# can't use AnimationPlayer unfortunately, this is a very basic
# version that simply allows swapping frames in a given amount of time.
# supports looping and flipping frames

# TODO: make generic, right now only used for bike spritesheet

var anim := ""
var finished := false
var flip_h := false
var frame := 0
var just_finished := false
var speed_scale := 1.0
var time_elapsed := 0.0

# return true we started a new animation
func play(anim_name: String) -> bool:
	if anim == anim_name:
		return false
	anim = anim_name
	frame = 0
	time_elapsed = 0.0
	finished = false
	just_finished = false
	return true

func restart() -> void:
	frame = 0
	time_elapsed = 0.0
	finished = false
	just_finished = false

func advance(dt: float) -> void:
	just_finished = false
	if anim == "" or finished:
		return

	var data: Dictionary = BikeSprites.ANIMS[anim]
	var frames: Array = data.frames
	var loops: bool = data.loop
	var fps: float = data.fps

	if frames.size() <= 1 or fps <= 0.0:
		finished = not loops
		just_finished = finished
		return

	# move forward
	var step := 1.0 / fps
	time_elapsed += dt * speed_scale
	while time_elapsed >= step:
		time_elapsed -= step
		frame += 1
		if frame < frames.size():
			continue
		if loops:
			frame = 0
		else:
			frame = frames.size() - 1
			finished = true
			just_finished = true
			return

func get_cell() -> Vector2i:
	if anim == "":
		return Vector2i.ZERO
	var frames: Array = BikeSprites.ANIMS[anim].frames
	var cell: Vector2i = frames[frame]
	return cell
