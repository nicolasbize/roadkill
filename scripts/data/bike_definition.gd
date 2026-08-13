class_name BikeDefinition
extends Resource

# TODO: make weapons their own entities. right now this is ok for the jam we're only making
#       it a part of the cop bike

@export var display_name := ""

# 10x10 grid 32x32px animations
@export_group("Display")
@export var ground_texture: Texture2D
@export var texture: Texture2D

# weapons are stuck to bikes for now, they're not their own entities
@export_group("Weapon")
@export var weapon_punch_damage := 0
@export var weapon_texture: Texture2D

@export_group("Handling")
@export_range(0.05, 0.30, 0.01) var max_steer_angle := 0.15
@export_range(0.0, 6.0, 0.1) var rolling_resistance := 1.5 # m/s^2

@export_group("Engine")
@export_range(4.0, 24.0, 0.5) var brake_decel := 14.0 # m/s^2
@export_range(4.0, 24.0, 0.5) var engine_accel := 12.0 # m/s^2
@export_range(60.0, 260.0, 5.0) var max_speed_kph := 180.0

func is_valid() -> bool:
	return texture != null and engine_accel > rolling_resistance and max_speed_kph > 0.0
