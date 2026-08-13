class_name CreditsScreen
extends MenuScreen

@onready var animation_player: AnimationPlayer = %AnimationPlayer

var is_done := false

func _ready() -> void:
	animation_player.animation_finished.connect(on_animation_finished)

func on_animation_finished(_anim_name: String) -> void:
	is_done = true

func _process(_delta: float) -> void:
	if is_done and Input.is_action_just_pressed("punch"):
		nav_forward.emit()
	
