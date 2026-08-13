class_name UsaTrack
extends TrackDefinition

# USA is a desert map with a few tight corners

func lay_out(track: Track) -> void:
	# opening is fast, no need to brake.
	track.add_straight(120)
	track.add_curve(40, 90, 40, 240.0)
	track.add_straight(80)
	track.add_curve(30, 60, 30, -95.0)
	track.add_straight(60)
	track.add_hill(25, 20, 25, 20.0)
	track.add_curve(30, 75, 30, 75.0)
	track.add_hill(25, 25, 25, -14.0)
	track.add_straight(130)
	track.add_curve(20, 16, 20, 85.0)
	track.add_curve(20, 16, 20, -85.0)
	track.add_straight(110, "turn_right", Track.LEFT)

	# two tight corners
	track.add_curve(25, 85, 25, 55.0)
	track.add_straight(90)
	track.add_hill(20, 12, 20, -16.0)
	track.add_straight(50, "turn_right", Track.LEFT)
	track.add_curve(20, 18, 20, 70.0)
	track.add_curve(20, 18, 20, -70.0)
	track.add_curve(20, 18, 20, 70.0)
	track.add_straight(110, "turn_left", Track.RIGHT)
	track.add_curve(30, 95, 30, -42.0)
	track.add_straight(140, "turn_right", Track.LEFT)
	track.add_curve(25, 60, 25, 65.0)
	track.add_curve(20, 60, 20, 65.0)
	track.add_straight(120)
 
	# climb, mostly straight with one tight corner
	track.add_curved_hill(40, 80, 40, 170.0, 32.0)
	track.add_straight(90)
	track.add_hill(25, 15, 25, 18.0)
	track.add_curve(30, 55, 30, -80.0)
	track.add_curved_hill(30, 60, 30, 120.0, 26.0)
	track.add_straight(130, "turn_right", Track.LEFT)
	track.add_curve(25, 80, 25, 58.0)
	track.add_straight(100)
	track.add_hill(20, 14, 20, 14.0)
 
	# super fast descent with 2 long turns
	track.add_curved_hill(40, 70, 40, -150.0, -30.0)
	track.add_straight(150)
	track.add_curve(20, 16, 20, 90.0)
	track.add_curve(20, 16, 20, -90.0)
	track.add_curved_hill(30, 60, 30, 100.0, -28.0)
	track.add_straight(120, "turn_left", Track.RIGHT)
	track.add_curve(30, 85, 30, -68.0)
	track.add_hill(25, 20, 25, -20.0)
	track.add_straight(160)
	track.add_curve(40, 80, 40, 200.0)
	track.add_straight(50, "turn_right", Track.LEFT)
 
	# lots of small turns, make it triky to go through
	track.add_curve(25, 70, 25, 62.0)
	track.add_straight(80, "turn_left", Track.RIGHT)
	track.add_curve(20, 20, 20, -58.0)
	track.add_curve(20, 20, 20, 58.0)
	track.add_hill(20, 15, 20, -18.0)
	track.add_straight(110, "turn_left", Track.RIGHT)
	track.add_curve(30, 80, 30, -52.0)
	track.add_straight(140)
	track.add_curved_hill(25, 60, 25, 105.0, 22.0)
	track.add_straight(50, "turn_left", Track.RIGHT)
	track.add_curve(25, 55, 25, -66.0)
	track.add_straight(120, "turn_left", Track.RIGHT)
 
	# longest straigght to finish the map
	track.add_curve(30, 90, 30, -48.0)
	track.add_straight(130)
	track.add_curve(25, 70, 25, 72.0)
	track.add_straight(90)
	track.add_hill(20, 12, 20, 16.0)
	track.add_curve(30, 55, 30, -88.0)
	track.add_straight(220)
	track.add_curve(40, 60, 40, 160.0)
	track.add_straight(130)
 
