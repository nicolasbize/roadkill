extends Node

var unlocked_bikes := [true, false, false, false, false]
var best_map_times := [0, 0, 0, 0] # ms for each map
var best_map_positions := [0, 0, 0, 0]
var best_map_takedowns := [0, 0, 0, 0]

var unlock_conditions := ["", "ELIMS 10\nIN USA", "FINISH JAP\nUNDER 2:45", "FINISH FRA\n1ST PLACE", "UNLOCK 3\n+ KONAMI"]

var current_bike_index := 0
var current_map_index := 0

var current_race_finish_position := 0
var current_race_finish_time := 0
var current_race_finish_takedowns := 0

var has_won_game := false

func _ready() -> void:
	GameEvents.race_started.connect(on_race_started)
	
func on_race_started() -> void:
	current_race_finish_position = 0
	current_race_finish_time = 0
	current_race_finish_takedowns = 0
