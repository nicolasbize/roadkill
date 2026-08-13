class_name TrackDefinition
extends Resource

# base class for various tracks

const START_RUNIN := 20 # position start a bit further so we can see it
const FINISH_RUNOUT := 100 # extend track a bit after finish

# common textures for some of the static props
const SHARED_TEXTURES := {
	Track.SIGN_LEFT: preload("res://assets/textures/signs/turn_left.png"),
	Track.SIGN_RIGHT: preload("res://assets/textures/signs/turn_right.png"),
	Track.START: preload("res://assets/textures/signs/start.png"),
	Track.FINISH: preload("res://assets/textures/signs/finish.png"),
}

@export var display_name := ""

@export_group("Look")
@export var theme: RoadTheme
@export var sky_texture: Texture2D
@export var backdrop_texture: Texture2D
@export var drives_on_left := false # for our uk/japanese friends

@export_group("Props")
@export var tree_texture: Texture2D # trees and rocks are the only things we collide with
@export var rock_texture: Texture2D
@export var decorations: Dictionary[String, Texture2D]
@export var scenery: Array[SceneryRun] = []

func get_prop_textures() -> Dictionary:
	var textures := SHARED_TEXTURES.duplicate()
	textures[Track.TREE] = tree_texture
	textures[Track.ROCK] = rock_texture
	textures.merge(decorations, true)
	return textures

# common track instructions, includes start/finish and other props 
func build() -> Track:
	var track := Track.new()

	track.add_straight(START_RUNIN)
	track.add_gantry(Track.START)
	lay_out(track)
	track.add_finish_line()
	track.add_straight(FINISH_RUNOUT)

	var length := track.segments.size()
	for run in scenery:
		if run == null or run.kinds.is_empty():
			continue
		track.add_scenery_run(run.kinds, length, run.spacing, run.offset, run.jitter, 0)

	track.index_crashables()
	return track

# Override this 
func lay_out(_track: Track) -> void:
	print("Track has no layout defined")
