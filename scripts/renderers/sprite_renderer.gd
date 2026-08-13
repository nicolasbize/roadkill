class_name SpriteRenderer
extends RefCounted

# Draw everything other than the road: bikers, cars and props
# Road is drawn first in RoadRenderer

const SHADOW_DEPTH_BIAS := 0.01 # draw shadow right below the bike
const SHADOW_DROP := 1.0 # px down so the sprite is right under the tire
const SHADOW_MIN_SCALE := 0.35 # scale down to 35% when flying 6m high
const SHADOW_FADE_HEIGHT := 6.0
const WEAPON_CELL_SIZE := 64.0
const WEAPON_DEPTH_BIAS := 0.01 # draw right below player

var cell_height := 0.0 # m., what 32px reprensents in game
var enemy_textures: Array[Texture2D]
var flash_texture: Texture2D
var ground_texture: Texture2D
var oncoming_car_textures: Array[Texture2D]
var player_texture: Texture2D
var prop_textures : Dictionary = {} # not sure why godot throws a fit here when typing this dictionary
var same_way_car_textures: Array[Texture2D]
var shadow_texture: Texture2D
var weapon_texture: Texture2D

var draw_queue: Array[Dictionary] = [] # to be drawn in order

func _init(player_tex: Texture2D, enemy_texs: Array[Texture2D], flash_tex: Texture2D, ground_tex: Texture2D, camera: RoadCamera) -> void:
	player_texture = player_tex
	enemy_textures = enemy_texs
	flash_texture = flash_tex
	ground_texture = ground_tex
	cell_height = camera.get_world_height_for_pixels(BikeSprites.CELL_SIZE)

func draw_all(canvas: CanvasItem, camera: RoadCamera, road: RoadRenderer, track: Track,	enemies: Array[Enemy], cars: Array[Car], bike: PlayerBike,	is_player_pinned := true) -> void:
	draw_queue.clear()
	for prop in track.props:
		queue_prop(prop, camera, road, track)
	for enemy in enemies:
		var is_flashing := enemy.flash_timer > 0.0
		var texture := flash_texture if is_flashing else enemy_textures[enemy.texture_index]
		var entry := queue_on_road(camera, road, track.gap_z(enemy.z, camera.z), enemy.x, cell_source(enemy.animator.get_cell()), cell_height, enemy.animator.flip_h, enemy.tint, texture)
		if not entry.is_empty() and not enemy.crashed: # no shadow if crashed
			queue_shadow(camera, entry.distance, entry.center_x, entry.ground_y, 0.0, enemy.animator.anim, enemy.animator.flip_h)

	if bike.dropped.active:
		queue_on_road(camera, road, track.gap_z(bike.dropped.z, camera.z), bike.dropped.x, cell_source(Vector2i.ZERO), cell_height, false, Color.WHITE, ground_texture, true)

	for car in cars:
		var car_textures := same_way_car_textures if car.direction > 0.0 else oncoming_car_textures
		var distance := track.gap_z(car.z, camera.z)
		var car_texture := car_textures[car.texture_index % car_textures.size()]
		var car_rect := Rect2(car.get_frame(distance) * Car.CELL_SIZE, 0.0, Car.CELL_SIZE, Car.CELL_SIZE)
		queue_on_road(camera, road, distance, car.x, car_rect, cell_height, false, Color.WHITE, car_texture)

	queue_player(bike, camera, road, track, is_player_pinned)

	draw_queue.sort_custom(func(a, b): return a.distance > b.distance)
	for entry in draw_queue:
		draw_sprite(canvas, entry)

# extract frame from spritesheet
func cell_source(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * BikeSprites.CELL_SIZE, cell.y * BikeSprites.CELL_SIZE, BikeSprites.CELL_SIZE, BikeSprites.CELL_SIZE)

# add scenery prop to draw queue
func queue_prop(prop: Prop, camera: RoadCamera, road: RoadRenderer, track: Track) -> void:
	var distance := track.gap_z(prop.z, camera.z)
	if distance < 0.0 or distance > prop.max_distance:
		return # manual culling

	var texture: Texture2D = prop_textures.get(prop.kind)
	if texture == null:
		print("error getting prop texture %s", prop.kind)
		return

	var source := Rect2(Vector2.ZERO, texture.get_size())
	var world_height := camera.get_world_height_for_pixels(source.size.y)
	if prop.world_width > 0.0: # allow manual scaling of sprites (useful for start/finish gantries)
		world_height = prop.world_width * source.size.y / source.size.x
	world_height *= prop.world_scale

	queue_on_road(camera, road, distance, prop.x, source, world_height, prop.flip_h, Color.WHITE, texture)

# queue-render objects that are sitting on a road (cars, bikes, etc.)
func queue_on_road(camera: RoadCamera, road: RoadRenderer, distance: float, lateral: float, source: Rect2, world_height: float, flip_h: bool, tint: Color, texture: Texture2D, cap_native := false) -> Dictionary:
	# first find where the ground is at distance z
	var ground := road.get_info(distance)
	if ground.is_empty():
		return {}

	# project into game dimensions (px)
	var height := roundf(camera.get_scale(distance) * world_height * RoadCamera.VIEWPORT_HEIGHT / 2.0)
	if cap_native:
		height = minf(height, source.size.y)
	var width := roundf(height * source.size.x / source.size.y)
	if height < 1.0 or width < 1.0: # sub-1px: don't draw
		return {}
	var entry := {
		"distance": distance,
		"center_x": camera.project_x(ground.offset + lateral, distance),
		"ground_y": roundf(camera.project_y(ground.elevation, distance)),
		"clip_y": ground.clip_y,
		"height": height,
		"width": width,
		"source": source,
		"flip_h": flip_h,
		"tint": tint,
		"texture": texture,
	}
	draw_queue.append(entry)
	return entry

func queue_player(bike: PlayerBike, camera: RoadCamera, road: RoadRenderer, track: Track, is_pinned: bool) -> void:
	var distance := camera.bike_distance if is_pinned else track.gap_z(bike.z, camera.z)
	var ground := road.get_info(distance)
	if ground.is_empty():
		return

	var center_x := camera.project_x(ground.offset + bike.x, distance) + camera.shake.x

	if not bike.is_down():
		queue_shadow(camera, distance, center_x,
				roundf(camera.project_y(ground.elevation, distance)) + camera.shake.y,
				maxf(bike.y - ground.elevation, 0.0),
				bike.animator.anim, bike.animator.flip_h)

	# the bike itself, at its own elevation rather than the road's
	var size := roundf(camera.get_scale(distance) * cell_height
			* RoadCamera.VIEWPORT_HEIGHT / 2.0)
	var ground_y := roundf(camera.project_y(bike.y, distance)) + camera.shake.y
	var flashing := bike.flash_timer > 0.0 and flash_texture != null
	draw_queue.append({
		"distance": distance,
		"center_x": center_x,
		"ground_y": ground_y,
		"clip_y": RoadCamera.VIEWPORT_HEIGHT,
		"height": size,
		"width": size,
		"source": cell_source(bike.animator.get_cell()),
		"flip_h": bike.animator.flip_h,
		"tint": Color.WHITE,
		"texture": flash_texture if flashing else player_texture,
	})
	queue_weapon(bike, distance, center_x, ground_y, size)

func queue_weapon(bike: PlayerBike, distance: float, center_x: float,
		ground_y: float, size: float) -> void:
	if weapon_texture == null:
		return
	if bike.state != PlayerBike.State.Attacking or bike.attack_anim != "punch":
		return

	var span := size * 2.0
	draw_queue.append({
		"distance": distance - WEAPON_DEPTH_BIAS,
		"center_x": center_x,
		"ground_y": ground_y + size * 0.5,
		"clip_y": RoadCamera.VIEWPORT_HEIGHT,
		"height": span,
		"width": span,
		"source": Rect2(bike.animator.frame * WEAPON_CELL_SIZE, 0.0, WEAPON_CELL_SIZE, WEAPON_CELL_SIZE),
		"flip_h": bike.animator.flip_h,
		"tint": Color.WHITE,
		"texture": weapon_texture,
	})

# `lift` is meters of air; rivals are always zero since only the player flies.
func queue_shadow(camera: RoadCamera, distance: float, center_x: float,
		ground_y: float, lift: float, anim: String, flip_h: bool) -> void:
	if shadow_texture == null:
		return

	var shrink := lerpf(1.0, SHADOW_MIN_SCALE,
			clampf(lift / SHADOW_FADE_HEIGHT, 0.0, 1.0))
	var source := Rect2(Vector2.ZERO, shadow_texture.get_size())
	var world_h := camera.get_world_height_for_pixels(source.size.y) * shrink
	var height := roundf(camera.get_scale(distance) * world_h
			* RoadCamera.VIEWPORT_HEIGHT / 2.0)
	if height < 1.0:
		return

	# the pose offset is in source pixels, so it has to scale with distance
	# the same way the sprite does
	var drawn_cell := camera.get_scale(distance) * cell_height \
			* RoadCamera.VIEWPORT_HEIGHT / 2.0
	var shift := BikeSprites.get_shadow_offset(anim, flip_h) \
			* drawn_cell / BikeSprites.CELL_SIZE

	draw_queue.append({
		"distance": distance + SHADOW_DEPTH_BIAS,
		"center_x": center_x + shift,
		"ground_y": ground_y + SHADOW_DROP,
		"clip_y": RoadCamera.VIEWPORT_HEIGHT,
		"height": height,
		"width": roundf(height * source.size.x / source.size.y),
		"source": source,
		"flip_h": false,
		"tint": Color.WHITE,
		"texture": shadow_texture,
	})

func draw_sprite(canvas: CanvasItem, entry: Dictionary) -> void:
	var height: float = entry.height
	var width: float = entry.width
	var ground_y: float = entry.ground_y
	var top := ground_y - height
	var bottom: float = minf(ground_y, entry.clip_y)
	if bottom <= top: 
		return # completely hidden behind road crest
	var visible := bottom - top
	var left := roundf(entry.center_x - width / 2.0)
	var region: Rect2 = entry.source
	var source := Rect2(region.position, Vector2(region.size.x, region.size.y * visible / height))
	var target := Rect2(left, top, width, visible)

	if entry.flip_h: # requires manual mirroring by tweaking canvas transform, couldn't find a better way to do this...
		canvas.draw_set_transform(Vector2(2.0 * left + width, 0.0), 0.0, Vector2(-1.0, 1.0))

	canvas.draw_texture_rect_region(entry.texture, target, source, entry.tint)

	if entry.flip_h: # reset canvas
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
