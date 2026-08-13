class_name MapSelectionScreen
extends MenuScreen

@onready var map_1: TextureRect = %"Map-1"
@onready var map_2: TextureRect = %"Map-2"
@onready var map_3: TextureRect = %"Map-3"
@onready var map_4: TextureRect = %"Map-4"

var current_index := 0
var map_nodes : Array[TextureRect] = []

func _ready() -> void:
	map_nodes.append_array([map_1, map_2, map_3, map_4])
	refresh()

func reset() -> void:
	current_index = 0
	refresh()

func _process(_delta: float) -> void:
	if not is_active:
		return
	if Input.is_action_just_pressed("accelerate") or Input.is_action_just_pressed("menu_up"):
		select_previous()
	if Input.is_action_just_pressed("brake") or Input.is_action_just_pressed("menu_down"):
		select_next()
	if Input.is_action_just_pressed("kick"):
		nav_back.emit()
	elif Input.is_action_just_pressed("punch"):
		is_active = false
		GameEvents.menu_selected.emit()
		GameState.current_map_index = current_index
		nav_forward.emit()
	
func select_previous() -> void:
	GameEvents.menu_navigated.emit()
	current_index = clampi(current_index - 1, 0, map_nodes.size() - 1)
	refresh()
	
func select_next() -> void:
	GameEvents.menu_navigated.emit()
	current_index = clampi(current_index + 1, 0, map_nodes.size() - 1)
	refresh()

func refresh() -> void:
	for i in map_nodes.size():
		map_nodes[i].visible = current_index == i
		
	
