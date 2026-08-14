class_name CreditsScreen
extends MenuScreen

@onready var timer: Timer = $Timer
@onready var credits_animation: AnimationPlayer = $CreditsAnimation

var is_done := false

func _ready() -> void:
	GameEvents.credits_roll.emit()
	credits_animation.animation_finished.connect(on_animation_finished)
	timer.timeout.connect(on_timeout)

func on_timeout() -> void:
	credits_animation.play("scroll")

func on_animation_finished(_anim_name: String) -> void:
	is_done = true

func _process(_delta: float) -> void:
	if is_done and Input.is_action_just_pressed("punch"):
		nav_forward.emit()
	
