class_name MobileGame
extends Node2D

# Entry point to play on phones
# Easier to draw them than to use 

const GAME_WIDTH := 64.0
const SCREEN_WIDTH := 128.0
const SCREEN_HEIGHT := 64.0

# Left pad
const STICK_CENTER := Vector2(16, 32)
const STICK_RADIUS := 10.0 # px, knob travel distance
const KNOB_RADIUS := 5.0
const DEAD_ZONE := 0.25 # % of full travel before anything registers

## Right pad.
const BUTTONS := {
	"punch": {"center": Vector2(112, 20)},
	"kick": {"center": Vector2(112, 44)},
}
const BUTTON_RADIUS := 10.0

@export var pad_color := Color("2a2a33")
@export var knob_color := Color("8e8e9c")
@export var press_color := Color("fff1e8")

var axis_held := {}
var button_touch := {}
var stick := Vector2.ZERO
var stick_touch := -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			press(event.index, event.position)
		else:
			release(event.index)
		queue_redraw()
	elif event is InputEventScreenDrag:
		drag(event.index, event.position)
		queue_redraw()

func _process(_delta: float) -> void:
	# Axes go through every frame: nothing reads just_pressed on these, and the
	# strength has to stay live for Input.get_axis to return anything analogue.
	drive_axis("steer_left", "steer_right", stick.x)
	drive_axis("brake", "accelerate", -stick.y)   # screen Y grows downwards
		
func _draw() -> void:
	draw_circle(STICK_CENTER, STICK_RADIUS, pad_color)
	draw_circle(STICK_CENTER + stick * STICK_RADIUS, KNOB_RADIUS,
			press_color if stick_touch != -1 else knob_color)

	for action in BUTTONS:
		var button: Dictionary = BUTTONS[action]
		var held := button_touch.has(action)
		draw_circle(button.center, BUTTON_RADIUS, press_color if held else pad_color)
		draw_circle(button.center, BUTTON_RADIUS - 2.0, pad_color if held else knob_color)

func press(index: int, at: Vector2) -> void:
	for action in BUTTONS:
		var center: Vector2 = BUTTONS[action].center
		if at.distance_to(center) <= BUTTON_RADIUS:
			button_touch[action] = index
			# buttons driven from event, not _process
			Input.action_press(action)
			return

	# anything else on the left half grabs the stick
	if stick_touch == -1 and at.x < GAME_WIDTH * 0.5:
		stick_touch = index
		drag(index, at)

func drag(index: int, at: Vector2) -> void:
	if index != stick_touch:
		return
	var offset := (at - STICK_CENTER) / STICK_RADIUS
	stick = offset.limit_length(1.0)

func release(index: int) -> void:
	if index == stick_touch:
		stick_touch = -1
		stick = Vector2.ZERO

	for action in button_touch.keys():
		if button_touch[action] == index:
			button_touch.erase(action)
			Input.action_release(action)

func drive_axis(negative: String, positive: String, value: float) -> void:
	set_axis(negative, -value)
	set_axis(positive, value)
		
func set_axis(action: String, value: float) -> void:
	if value > DEAD_ZONE:
		Input.action_press(action, minf(value, 1.0))
		axis_held[action] = true
	elif axis_held.get(action, false):
		Input.action_release(action)
		axis_held[action] = false
