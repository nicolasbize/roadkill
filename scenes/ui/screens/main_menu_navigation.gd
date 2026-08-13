class_name MainMenuNavigation
extends Control

signal completed

@onready var map_selection_screen: MapSelectionScreen = $Scroller/MapSelectionScreen
@onready var scroller: Control = %Scroller
@onready var selection_screen: BikeSelectionScreen = %SelectionScreen
@onready var title_screen: TitleScreen = %TitleScreen

var current_index := 0
var is_transitioning := false
var screens : Array[MenuScreen] = []

func _ready() -> void:
	screens.append_array([title_screen, selection_screen, map_selection_screen])
	title_screen.nav_forward.connect(nav_next)
	selection_screen.nav_back.connect(nav_back)
	selection_screen.nav_forward.connect(nav_next)
	map_selection_screen.nav_back.connect(nav_back)
	map_selection_screen.nav_forward.connect(nav_next)
	GameEvents.main_menu_started.emit()
	refresh()
	
func nav_next() -> void:
	if current_index == screens.size() - 1:
		is_transitioning = true
		completed.emit()
		return
	if not is_transitioning:
		screens[current_index].is_active = false
		var new_position := scroller.position - Vector2.RIGHT * 64
		current_index = (current_index + 1) % screens.size() 
		screens[current_index].reset()
		is_transitioning = true
		var tween := create_tween()
		tween.tween_property(scroller, "position", new_position, 0.2)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_callback(refresh)

func nav_back() -> void:
	if not is_transitioning and current_index > 0:
		screens[current_index].is_active = false
		var new_position := scroller.position + Vector2.RIGHT * 64
		current_index -= 1
		is_transitioning = true
		var tween := create_tween()
		tween.tween_property(scroller, "position", new_position, 0.2)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_callback(refresh)

func refresh() -> void:
	is_transitioning = false
	screens[current_index].is_active = true
	
