class_name LogoScreen
extends Control

signal completed

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(on_anim_finished)

func on_anim_finished(_name) -> void:
	completed.emit()
