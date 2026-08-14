class_name World
extends Node2D

# main entry point, everything happens here

@onready var engine_sound: AudioStreamPlayer = %EngineSound
@onready var engine_zzz_sound: AudioStreamPlayer = %EngineZzzSound
@onready var position_label: Label = %PositionLabel
@onready var race_progress_indicator: HBoxContainer = %RaceProgressIndicator
@onready var sky_background: Sprite2D = $Background
@onready var speed_indicator: Sprite2D = %SpeedIndicator
@onready var speed_label: Label = $SpeedLabel

const ATTACK_ACTIONS: Array[String] = ["punch", "kick"]
const BACKDROP_HEIGHT := 32.0
const BACKDROP_PARALLAX_SPEED := 1.0 # 512px width == 360deg rotation
const COUNTDOWN_FRAMES := 4
const COUNTDOWN_Y_POS := 16.0   # top of the countdown sprite, in screen pixels
const DURATION_BLINK_PROGRESS := 400
const ENEMY_COUNT := 12
const ENEMY_CRASH_SHAKE := 0.55
const HIT_STOP_DURATIONS := {"punch": 0.06, "kick": 0.09} # pause for more impact
const IMPACT_Y_POS := {"punch": 42.0, "kick": 50.0} # vertical position of sparks fx
const MIN_FRAMERATE := 30.0   # clamp dt in case we miss frames
const OFFROAD_RUMBLE := 0.3
const PLAYER_CRASH_SHAKE := 1.0
const SKY_TEXTURE_WIDTH := 128.0
const SOUND_ENGINE_BUS := "Race"
const SOUND_ENGINE_FADE_TIME := 3.0
const SOUND_ENGINE_GEARS := 5
const SOUND_ENGINE_PITCH_LOW := 0.75
const SOUND_ENGINE_PITCH_HIGH := 1.70
const SOUND_ENGINE_GEAR_CURVE := 0.7
const TRAFFIC_GRID_CLEARANCE := 150.0
const WARNING_Y_POS := 12.0

@export_category("Current Setup")
@export var bike_definition: BikeDefinition
@export var track_definition: TrackDefinition
@export var spark_scene: PackedScene
@export_category("Textures")
@export var countdown_texture: Texture2D                   # 4 frames: 3, 2, 1, GO
@export var enemy_textures: Array[Texture2D]
@export var finished_texture: Texture2D
@export var flash_texture: Texture2D   # the enemy sheet, all in white
@export var oncoming_car_textures: Array[Texture2D]
@export var same_way_car_textures: Array[Texture2D]
@export var shadow_texture: Texture2D
@export var progress_race_tick: Texture2D
@export var warning_texture: Texture2D

var audio_bus_index := -1
var backdrop_scroll := 0.0
var backdrop_texture: Texture2D
var bike: PlayerBike
var camera: RoadCamera
var current_coundown := 3
var enemies: EnemyProcessor
var final_position := 0
var finish_handled := false
var heading := 0.0 # lateral direction used to scroll backdrops
var hit_stop_timer := 0.0
var impacts := Impacts.new()
var is_show_progress := true
var lean_sparks := LeanSparks.new()
var progress_original_ticks : Array[Texture2D] = []
var race := Race.new()
var road: RoadRenderer
var sky_texture: Texture2D
var sprite_renderer: SpriteRenderer
var time_last_progress_check := Time.get_ticks_msec()
var time_start_race := 0
var track: Track
var traffic: TrafficProcessor
var wind := WindStreaks.new()
var shaker := ScreenShake.new()
var warning := TrafficWarning.new()

func _ready() -> void:
	assert(track_definition != null, "World needs a TrackDefinition")
	assert(bike_definition != null, "World needs a BikeDefinition")
	var traffic_side := -1.0 if track_definition.drives_on_left else 1.0
	sky_background.texture = track_definition.sky_texture
	backdrop_texture = track_definition.backdrop_texture
	track = track_definition.build()
	road = RoadRenderer.new(track_definition.theme)
	camera = RoadCamera.new()
	bike = PlayerBike.new(bike_definition, traffic_side)
	bike.z = camera.bike_distance

	camera.move_to(bike.z - camera.bike_distance, track)

	enemy_textures.erase(bike_definition.texture) # prevent player from being the same color
	enemies = EnemyProcessor.new()
	enemies.spawn(ENEMY_COUNT, track, bike.z, enemy_textures.size(), traffic_side)
	sprite_renderer = SpriteRenderer.new(bike_definition.texture, enemy_textures, flash_texture,
			bike_definition.ground_texture, camera)
	sprite_renderer.same_way_car_textures = same_way_car_textures
	sprite_renderer.shadow_texture = shadow_texture
	sprite_renderer.flash_texture = flash_texture
	sprite_renderer.weapon_texture = bike_definition.weapon_texture
	sprite_renderer.prop_textures = track_definition.get_prop_textures()

	traffic = TrafficProcessor.new()
	traffic.spread(track, enemies.get_furthest_z() + TRAFFIC_GRID_CLEARANCE,
			oncoming_car_textures.size(), same_way_car_textures.size(), traffic_side)
	sprite_renderer.oncoming_car_textures = oncoming_car_textures
	
	for texture_rect: TextureRect in race_progress_indicator.get_children():
		progress_original_ticks.append(texture_rect.texture)
	
	GameEvents.race_started.connect(on_race_started)

	audio_bus_index = AudioServer.get_bus_index(SOUND_ENGINE_BUS)
	# a previous race left it muted, so put it back before this one starts
	if audio_bus_index >= 0:
		AudioServer.set_bus_mute(audio_bus_index, false)
		AudioServer.set_bus_volume_db(audio_bus_index, 0.0)

	race.start(track)

func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / MIN_FRAMERATE) # clamped delta in case we miss a big frame
	
	if hit_stop_timer > 0.0: # manual process_mode for hit stop
		hit_stop_timer -= delta
		return

	race.update(dt, bike.z)
	if race.is_moving():
		update_racing(dt)
	camera.follow(bike.x, dt)
	bike.update_animation(dt)
	speed_label.text = "%03d" % TrackHelper.ms_to_kmh(maxf(bike.speed, 0.0))
	check_countdown()
	update_hud()
	queue_redraw()

func update_racing(dt: float) -> void:
	camera.update_fov(bike.get_speed_ratio())
	var can_control := not race.is_finished()
	var throttle := Input.is_action_pressed("accelerate")
	var brake := Input.is_action_pressed("brake")
	var steer := 0.0
	if can_control and not bike.is_down():
		steer = Input.get_axis("steer_left", "steer_right")

	bike.update_speed(dt, throttle, brake)
	bike.z = track.get_track_z(bike.z + bike.speed * dt)
	bike.update_air(dt, track)
	
	if not race.is_finished(): # keep camera still
		camera.move_to(bike.z - camera.bike_distance, track)

	bike.update_recovery(dt, track)
	engine_sound.pitch_scale = get_bike_pitch(bike.get_speed_ratio())
	wind.update(dt, bike.speed)
	var curvature := track.get_curvature_at(camera.z)
	update_sky(dt, curvature)
	bike.update_steering(dt, steer, curvature)
	lean_sparks.update(dt, bike, camera)
	traffic.update(dt)
	warning.update(dt, traffic.list, track, bike.z, bike.speed)
	enemies.update(dt, track, bike, traffic.list)
	impacts.clear()
	# check for collisions after everyone has moved
	ContactSolver.resolve(dt, bike, enemies.list, track)
	CombatSolver.resolve(bike, enemies.list, track, impacts)
	CombatSolver.resolve_enemy_attacks(bike, enemies.list, track, impacts)
	TrafficSolver.resolve(dt, bike, enemies.list, traffic.list, track)
	PropSolver.resolve(bike, enemies.list, track)
	spawn_impact_effects() # draw on top of everything else
	for point in impacts.points:
		hit_stop_timer = maxf(hit_stop_timer, HIT_STOP_DURATIONS.get(point.kind))
	update_shake(dt)

	if can_control and bike.state == PlayerBike.State.Riding:
		var attack := read_attack_input()
		if not attack.is_empty():
			bike.start_attack(attack, CombatSolver.get_aim_side(bike, enemies.list, track))

# Returns the first attack pressed
func read_attack_input() -> String:
	for action in ATTACK_ACTIONS:
		if Input.is_action_just_pressed(action):
			return action
	return ""

func spawn_impact_effects() -> void:
	if spark_scene == null:
		return
	for point in impacts.points:
		var spark := spark_scene.instantiate() as Node2D
		add_child(spark)
		spark.position = project_impact(point.x, point.kind)

func update_shake(dt: float) -> void:
	if bike.check_and_reset_just_crashed():
		shaker.add(PLAYER_CRASH_SHAKE)
	for enemy in enemies.list:
		if enemy.check_and_reset_just_crashed():
			shaker.add(ENEMY_CRASH_SHAKE)
	shaker.set_rumble(bike.get_shake_ratio() * OFFROAD_RUMBLE)
	shaker.update(dt)
	camera.shake = shaker.offset

func project_impact(world_x: float, kind: String) -> Vector2:
	var screen_y: float = IMPACT_Y_POS.get(kind)
	var screen_x := roundf(camera.project_x(world_x, camera.bike_distance))
	return Vector2(screen_x, screen_y)

func update_sky(dt: float, curvature: float) -> void:
	# wrap texture to create skybox
	heading = fposmod(heading + curvature * bike.speed * dt, TAU)
	sky_background.region_rect.position.x = roundf(heading / TAU * SKY_TEXTURE_WIDTH)
	var backdrop_width := float(backdrop_texture.get_width())
	backdrop_scroll = fposmod(heading * backdrop_width * BACKDROP_PARALLAX_SPEED / TAU, backdrop_width)

func _draw() -> void:
	draw_backdrop()
	road.draw(self, camera, track)
	sprite_renderer.draw_all(self, camera, road, track, enemies.list, traffic.list, bike, not race.is_finished())
	lean_sparks.draw(self)
	wind.draw(self, camera, bike.speed, bike.get_boost_ratio())
	draw_traffic_warning()
	draw_countdown()
	draw_finished_sign()

func draw_countdown() -> void:
	var frame := race.get_countdown_frame()
	if frame < 0:
		return
	var size := countdown_texture.get_size()
	var cell := Vector2(size.x / COUNTDOWN_FRAMES, size.y)
	var left := roundf((RoadCamera.VIEWPORT_WIDTH - cell.x) / 2.0)
	draw_texture_rect_region(countdown_texture, Rect2(left, COUNTDOWN_Y_POS, cell.x, cell.y), Rect2(frame * cell.x, 0.0, cell.x, cell.y))

func draw_finished_sign() -> void:
	if race.is_finished():
		draw_texture_rect_region(finished_texture, Rect2(0, 0, 64, 64), Rect2(0, 0, 64, 64))

func draw_backdrop() -> void:
	var tex_width := float(backdrop_texture.get_width())
	var top := RoadCamera.HORIZON_HEIGHT - BACKDROP_HEIGHT + 1.0 + camera.shake.y
	var offset := roundf(backdrop_scroll)
	var first := minf(RoadCamera.VIEWPORT_WIDTH, tex_width - offset)
	# split into 2 draws for wrapping
	draw_texture_rect_region(backdrop_texture, Rect2(0.0, top, first, BACKDROP_HEIGHT), Rect2(offset, 0.0, first, BACKDROP_HEIGHT))
	var rest := RoadCamera.VIEWPORT_WIDTH - first
	if rest > 0.0:
		draw_texture_rect_region(backdrop_texture, Rect2(first, top, rest, BACKDROP_HEIGHT), Rect2(0.0, 0.0, rest, BACKDROP_HEIGHT))

func draw_traffic_warning() -> void:
	if not warning.is_flashing():
		return
	var size := warning_texture.get_size()
	var center_x := warning.get_screen_x(camera, road)
	var left := clampf(center_x - size.x * 0.5, 0.0, RoadCamera.VIEWPORT_WIDTH - size.x)
	draw_texture(warning_texture, Vector2(roundf(left), WARNING_Y_POS))
	
func check_countdown() -> void:
	var new_count := race.get_countdown_frame()
	if current_coundown != new_count:
		current_coundown = new_count
		if new_count < 3 and new_count > -1:
			GameEvents.countdown_given.emit()
		elif new_count == 3:
			GameEvents.race_started.emit()

func get_bike_pitch(speed_ratio: float) -> float:
	var r := pow(clampf(speed_ratio, 0.0, 1.0), SOUND_ENGINE_GEAR_CURVE)
	var gear := mini(int(r * SOUND_ENGINE_GEARS), SOUND_ENGINE_GEARS - 1)
	var within := r * SOUND_ENGINE_GEARS - gear
	return lerpf(SOUND_ENGINE_PITCH_LOW, SOUND_ENGINE_PITCH_HIGH, within)

func on_race_started() -> void:
	engine_zzz_sound.stop()
	engine_sound.play()
	time_start_race = Time.get_ticks_msec()

func update_hud() -> void:
	speed_label.text = "%03d" % TrackHelper.ms_to_kmh(maxf(bike.speed, 0.0))

	if race.is_finished() and not finish_handled:
		finish_handled = true
		final_position = get_race_position()
		GameState.current_race_finish_position = final_position
		GameState.current_race_finish_time = Time.get_ticks_msec() - time_start_race
		GameState.current_race_finish_takedowns = enemies.takedowns
		fade_out_race()

	var place := final_position if final_position > 0 else get_race_position()
	position_label.text = LabelUtils.get_ordinal(place)
	
	# we only have room for 5 green speed indicators
	var nb_speed_lights = max(0, floori(lerp(0.0, 1.0, bike.speed / bike.max_speed) * 5))
	for i in speed_indicator.get_child_count():
		speed_indicator.get_child(i).visible = i < nb_speed_lights
	if Time.get_ticks_msec() - time_last_progress_check > DURATION_BLINK_PROGRESS:
		time_last_progress_check = Time.get_ticks_msec()
		update_race_progression()

func update_race_progression() -> void:
	is_show_progress = !is_show_progress
	var current_frame := clampi((lerp(0.0, 1.0, bike.z / track.finish_z) * 8), 0, 7)
	for i in race_progress_indicator.get_child_count():
		if i != current_frame:
			race_progress_indicator.get_child(i).texture = progress_original_ticks[i]
		else:
			if is_show_progress:
				race_progress_indicator.get_child(i).texture = progress_race_tick
			else:
				race_progress_indicator.get_child(i).texture = progress_original_ticks[i]

func get_race_position() -> int:
	var place := 1
	for enemy in enemies.list:
		if enemy.z > bike.z:
			place += 1
	return place

func fade_out_race() -> void:
	if audio_bus_index < 0:
		print("Audio bus is missing")
		return
	var from := db_to_linear(AudioServer.get_bus_volume_db(audio_bus_index))
	var tween := create_tween()
	tween.tween_method(set_race_volume, from, 0.0, SOUND_ENGINE_FADE_TIME)
	tween.tween_callback(func() -> void:
		AudioServer.set_bus_mute(audio_bus_index, true)
		GameEvents.ready_for_results.emit())

func set_race_volume(linear: float) -> void:
	# linear_to_db(0) is -infinity, go for 0.0001 instead
	AudioServer.set_bus_volume_db(audio_bus_index, linear_to_db(maxf(linear, 0.0001)))
