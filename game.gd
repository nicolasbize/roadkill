class_name Game
extends Control

const CREDITS_BLUEPRINT := preload("res://scenes/ui/screens/credits_screen.tscn")
const MENU_NAV_BLUEPRINT := preload("res://scenes/ui/screens/main_menu_navigation.tscn")
const RESULTS_BLUEPRINT := preload("res://scenes/ui/screens/race_results_screen.tscn")
const TRANSITION_BLUEPRINT := preload("res://scenes/ui/transition.tscn")
const WORLD_BLUEPRINT := preload("res://scenes/world/world.tscn")

@onready var logo_screen: LogoScreen = $LogoScreen
@onready var background: ColorRect = $Background

const bikes := [
	preload("res://resources/bikes/bike-xo-papio.tres"),
	preload("res://resources/bikes/bike-gsx-8r.tres"),
	preload("res://resources/bikes/bike-ninja-650.tres"),
	preload("res://resources/bikes/bike-ymh-r7.tres"),
	preload("res://resources/bikes/bike-hd-glide.tres"),
]

const maps := [
	preload("res://resources/maps/usa_track.tres"),
	preload("res://resources/maps/italy_track.tres"),
	preload("res://resources/maps/france_track.tres"),
	preload("res://resources/maps/japan_track.tres"),
]

enum Screen {Logo, Title, Selection, InGame, Results, Credits}

var credits: CreditsScreen = null
var current_screen := Screen.Logo
var is_back_from_race := false
var menu_navigation : MainMenuNavigation = null
var results: RaceResultsScreen = null
var selection_screen : Control = null
var transition : Transition = null
var world: World = null

func _ready() -> void:
	logo_screen.completed.connect(start_new_transition)
	GameEvents.race_finished.connect(on_race_finished)

func start_new_transition() -> void:
	transition = TRANSITION_BLUEPRINT.instantiate()
	transition.in_completed.connect(on_transition_in)
	transition.out_completed.connect(on_transition_out)
	add_child(transition)

func on_transition_in() -> void:
	if current_screen == Screen.Logo:
		logo_screen.queue_free()
		current_screen = Screen.Title
		menu_navigation = MENU_NAV_BLUEPRINT.instantiate()
		menu_navigation.completed.connect(start_new_transition)
		background.add_sibling(menu_navigation)
	elif current_screen == Screen.Title:
		GameEvents.prepare_for_race.emit()
		is_back_from_race = false
		current_screen = Screen.InGame
		menu_navigation.queue_free()
		world = WORLD_BLUEPRINT.instantiate()
		world.track_definition = maps[GameState.current_map_index]
		world.bike_definition = bikes[GameState.current_bike_index]
		background.add_sibling(world)
	elif current_screen == Screen.InGame:
		current_screen = Screen.Results
		world.queue_free()
		results = RESULTS_BLUEPRINT.instantiate()
		results.nav_forward.connect(start_new_transition)
		background.add_sibling(results)
	elif current_screen == Screen.Results:
		results.queue_free()
		if GameState.has_won_game:
			current_screen = Screen.Credits
			credits = CREDITS_BLUEPRINT.instantiate()
			credits.nav_forward.connect(start_new_transition)
			background.add_sibling(credits)
		else:
			current_screen = Screen.Title
			menu_navigation = MENU_NAV_BLUEPRINT.instantiate()
			menu_navigation.completed.connect(start_new_transition)
			background.add_sibling(menu_navigation)
	elif current_screen == Screen.Credits:
		credits.queue_free()
		current_screen = Screen.Title
		menu_navigation = MENU_NAV_BLUEPRINT.instantiate()
		menu_navigation.completed.connect(start_new_transition)
		background.add_sibling(menu_navigation)
	transition.fade_out()
		
func on_transition_out() -> void:
	transition.queue_free()

func on_race_finished() -> void:
	if not is_back_from_race:
		is_back_from_race = true
		start_new_transition()
