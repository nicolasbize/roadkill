class_name TitleScreen
extends MenuScreen

var is_ready_to_play := false
var has_emitted_event := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_insert_animation() -> void:
	animation_player.play("insert")

func set_ready_to_play() -> void:
	is_ready_to_play = true

func _process(_delta: float) -> void:
	if not is_active:
		return
		
	if is_ready_to_play and Input.is_action_just_pressed("punch"):
		GameEvents.menu_selected.emit()
		nav_forward.emit()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if is_ready_to_play and event is InputEventMouseButton and event.is_pressed():
		nav_forward.emit()
