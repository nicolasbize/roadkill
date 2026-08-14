class_name AudioUtils
extends Node

# TODO: fade the music in and out
# TODO: lots of refactoring can happen here still

@onready var brake_sound: AudioStreamPlayer = %BrakeSound
@onready var countdown_sound: AudioStreamPlayer = %CountdownSound
@onready var crash_sound: AudioStreamPlayer = %CrashSound
@onready var go_sound: AudioStreamPlayer = %GoSound
@onready var kick_sound: AudioStreamPlayer = %KickSound
@onready var menu_navigate: AudioStreamPlayer = %MenuNavigate
@onready var menu_select: AudioStreamPlayer = %MenuSelect
@onready var miss_sound: AudioStreamPlayer = %MissSound
@onready var music_player: AudioStreamPlayer = %MusicPlayer
@onready var punch_sound: AudioStreamPlayer = %PunchSound
@onready var weapon_sound: AudioStreamPlayer = %WeaponSound

const MUSICS := {
	"menu": preload("res://assets/music/road-thrash-theme.mp3"),
	"results": preload("res://assets/music/results.mp3"),
	"credits": preload("res://assets/music/ending.mp3"),
	"theme-usa": preload("res://assets/music/hit-that-banjo.mp3"),
	"theme-france": preload("res://assets/music/fight-paris.mp3"),
	"theme-japan": preload("res://assets/music/hit-that-banjo.mp3"),
	"theme-italy": preload("res://assets/music/fight-paris.mp3"),
}

func _ready() -> void:
	GameEvents.menu_selected.connect(on_menu_selected)
	GameEvents.menu_navigated.connect(on_menu_navigated)
	GameEvents.countdown_given.connect(on_countdown)
	GameEvents.race_started.connect(on_race_started)
	GameEvents.punched.connect(on_punched)
	GameEvents.kicked.connect(on_kicked)
	GameEvents.hit_missed.connect(on_hit_miss)
	GameEvents.crashed.connect(on_crashed)
	GameEvents.screeched.connect(on_screeched)
	GameEvents.main_menu_started.connect(on_main_menu_started)
	GameEvents.prepare_for_race.connect(stop_music)
	GameEvents.results_shown.connect(on_results_shown)
	GameEvents.clubbed.connect(on_clubbed)
	GameEvents.credits_roll.connect(on_credits_roll)
	
func on_menu_selected() -> void:
	menu_select.play()
	
func on_menu_navigated() -> void:
	menu_navigate.play()

func on_countdown() -> void:
	countdown_sound.play()
	
func on_race_started() -> void:
	go_sound.play()
	await get_tree().create_timer(1.0).timeout
	var music := "theme-usa"
	if GameState.current_map_index == 2:
		music = "theme-france"
	if music_player.stream != MUSICS[music]:
		music_player.stream = MUSICS[music]
		music_player.play()

func on_main_menu_started() -> void:
	if music_player.stream != MUSICS["menu"]:
		music_player.stream = MUSICS["menu"]
		music_player.play()

func on_credits_roll() -> void:
	if music_player.stream != MUSICS["credits"]:
		music_player.stream = MUSICS["credits"]
		music_player.play()

func on_results_shown() -> void:
	if music_player.stream != MUSICS["results"]:
		music_player.stream = MUSICS["results"]
		music_player.play()

func on_crashed() -> void:
	crash_sound.play()

func on_clubbed() -> void:
	weapon_sound.play()

func on_punched() -> void:
	punch_sound.pitch_scale = randf_range(0.8, 1.2)
	punch_sound.play()

func on_kicked() -> void:
	kick_sound.pitch_scale = randf_range(0.8, 1.2)
	kick_sound.play()

func on_hit_miss() -> void:
	if not miss_sound.playing:
		miss_sound.pitch_scale = randf_range(0.8, 1.2)
		miss_sound.play()

func on_screeched() -> void:
	if not brake_sound.playing:
		brake_sound.play()

func stop_music() -> void:
	music_player.stop()
	music_player.stream = null
