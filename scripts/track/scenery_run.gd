class_name SceneryRun
extends Resource

# used to define what gets drawn to the sides of the road

@export var kinds: Array[String] = [] # keys into TrackDefinition.prop_textures
@export var spacing := 6 # road segments between repeats
@export var offset := 4.0 # how far from the edge by default
@export var jitter := 2.0 # fluctuate position a bit
