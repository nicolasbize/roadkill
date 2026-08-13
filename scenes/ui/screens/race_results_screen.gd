class_name RaceResultsScreen
extends MenuScreen

@onready var position_value: Label = %PositionValue
@onready var position_best: Label = %PositionBest
@onready var time_value: Label = %TimeValue
@onready var time_best: Label = %TimeBest
@onready var demo_value: Label = %DemoValue
@onready var demo_best: Label = %DemoBest
@onready var unlock_panel: ColorRect = %UnlockPanel
@onready var bike_unlocked_label: Label = %BikeUnlockedLabel
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

var time_start_menu := Time.get_ticks_msec()

func _ready() -> void:
	update_position()
	update_time()
	update_takedowns()
	if GameState.current_bike_index == GameState.unlocked_bikes.size() - 1 and GameState.current_race_finish_position == 1:
		GameState.has_won_game = true
	GameEvents.results_shown.emit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("punch") and Time.get_ticks_msec() - time_start_menu > 1000:
		nav_forward.emit()

func update_position() -> void:
	var prev_best_pos : int = GameState.best_map_positions[GameState.current_map_index]
	var new_position := GameState.current_race_finish_position
	position_value.text = LabelUtils.get_ordinal(new_position)
	if prev_best_pos == 0 or new_position < prev_best_pos:
		GameState.best_map_positions[GameState.current_map_index] = new_position
		position_best.visible = true
		if not GameState.unlocked_bikes[3]:
			if new_position == 1 and GameState.current_map_index == 2: # FRA
				GameState.unlocked_bikes[3] = true
				unlock_panel.visible = true
				audio_stream_player.play()
				bike_unlocked_label.text = "BIKE UNLOCKED"
			
func update_time() -> void:
	var prev_best_time : int = GameState.best_map_times[GameState.current_map_index]
	var new_time := GameState.current_race_finish_time
	time_value.text = LabelUtils.get_time(new_time)
	if prev_best_time == 0 or new_time < prev_best_time:
		GameState.best_map_times[GameState.current_map_index] = new_time
		time_best.visible = true
		if not GameState.unlocked_bikes[2]:
			if new_time < 165 * 1000 and GameState.current_map_index == 3: #JAP
				GameState.unlocked_bikes[2] = true
				unlock_panel.visible = true
				audio_stream_player.play()
				bike_unlocked_label.text = "BIKE UNLOCKED"
			
func update_takedowns() -> void:
	var prev_best_takedowns : int = GameState.best_map_takedowns[GameState.current_map_index]
	var new_takedowns := GameState.current_race_finish_takedowns
	demo_value.text = str(new_takedowns)
	if new_takedowns > prev_best_takedowns:
		GameState.best_map_takedowns[GameState.current_map_index] = new_takedowns
		demo_best.visible = true
		if not GameState.unlocked_bikes[1]:
			if new_takedowns >= 10 and GameState.current_map_index == 0: # USA
				GameState.unlocked_bikes[1] = true
				unlock_panel.visible = true
				audio_stream_player.play()
				bike_unlocked_label.text = "BIKE UNLOCKED"
			
