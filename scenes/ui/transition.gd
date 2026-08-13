class_name Transition
extends Control

signal in_completed
signal out_completed

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(on_anim_finished)

func fade_out() -> void:
	animation_player.play("transition_out")

func on_anim_finished(anim_name) -> void:
	if anim_name == "transition_in":
		in_completed.emit()
	else:
		out_completed.emit()
