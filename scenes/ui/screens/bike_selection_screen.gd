class_name BikeSelectionScreen
extends MenuScreen


@export var locked_textures : Array[Texture2D]
@export var textures : Array[Texture2D]

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var bike_scroller: Control = %BikeScroller
@onready var button_left: Button = %ButtonLeft
@onready var button_right: Button = %ButtonRight
@onready var left_texture: TextureRect = %LeftTexture
@onready var lock_frame: TextureRect = %LockFrame
@onready var mid_texture: TextureRect = %MidTexture
@onready var right_texture: TextureRect = %RightTexture
@onready var unlock_label: Label = %UnlockLabel

const KONAMI: Array[StringName] = [
	"accelerate", "accelerate", "brake", "brake",
	"steer_left", "steer_right", "steer_left", "steer_right",
	"kick", "punch",
]

const CODE_ACTIONS: Array[StringName] = [
	"steer_left", "steer_right", "accelerate", "brake", "kick", "punch",
]

var code_progress := 0
var current_index := 0
var is_transitioning := false
var just_unlocked_final_bike := false

func reset() -> void:
	current_index = 0
	refresh()

func _ready() -> void:
	button_left.pressed.connect(try_go_left)
	button_right.pressed.connect(try_go_right)
	refresh()

func _process(_delta: float) -> void:
	if not is_active:
		return
	if current_index < textures.size() - 1 or code_progress == 0:
		if Input.is_action_just_pressed("steer_right"):
			try_go_right()
		elif Input.is_action_just_pressed("steer_left"):
			try_go_left()
		elif Input.is_action_just_pressed("kick"):
			nav_back.emit()
		elif Input.is_action_just_pressed("punch"):
			if just_unlocked_final_bike:
				just_unlocked_final_bike = false
				return
			if not GameState.unlocked_bikes[current_index]:
				return
			GameState.current_bike_index = current_index
			GameEvents.menu_selected.emit()
			nav_forward.emit()

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for action in CODE_ACTIONS:
		if event.is_action_pressed(action):
			advance_code(action)
			return

func advance_code(action: StringName) -> void:
	if action == KONAMI[code_progress]:
		code_progress += 1
		if code_progress == KONAMI.size():
			code_progress = 0
			try_secret_unlock()
		return
 
	# wrong input restarts the code
	code_progress = 1 if action == KONAMI[0] else 0

func try_secret_unlock() -> void:
	var last := textures.size() - 1
	if GameState.unlocked_bikes[last]:
		return # already had it
	GameState.unlocked_bikes[last] = true
	audio_stream_player.play()
	just_unlocked_final_bike = true
	refresh()

func refresh() -> void:
	is_transitioning = false
	left_texture.texture = get_texture(current_index - 1)
	mid_texture.texture = get_texture(current_index)
	right_texture.texture = get_texture((current_index + 1) % (textures.size()))
	bike_scroller.position = Vector2(-64, 0)
	unlock_label.text = GameState.unlock_conditions[current_index]
	lock_frame.visible = GameState.unlocked_bikes[current_index] == false
	if current_index == textures.size() - 1:
		code_progress = 0

func get_texture(index: int) -> Texture2D:
	if GameState.unlocked_bikes[index]:
		return textures[index]
	else:
		return locked_textures[index]

func try_go_left() -> void:
	if not is_transitioning:
		lock_frame.visible = false
		GameEvents.menu_navigated.emit()
		current_index -= 1
		if current_index < 0:
			current_index = textures.size() - 1
		is_transitioning = true
		var tween := create_tween()
		tween.tween_property(bike_scroller, "position", Vector2(0, 0), 0.2)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_callback(refresh)

func try_go_right() -> void:
	if not is_transitioning:
		lock_frame.visible = false
		GameEvents.menu_navigated.emit()
		current_index = (current_index + 1) % textures.size() 
		is_transitioning = true
		var tween := create_tween()
		tween.tween_property(bike_scroller, "position", Vector2(-128, 0), 0.2)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_callback(refresh)
