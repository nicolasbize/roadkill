class_name FranceTrack
extends TrackDefinition

# France is more cuntryside, a bit longer and twistier

func lay_out(track: Track) -> void:
	# start off straight with a few curves
	track.add_straight(140)
	track.add_curve(40, 80, 40, 210.0)
	track.add_straight(70)
	track.add_curve(30, 70, 30, -85.0)
	track.add_straight(90)
	track.add_curve(25, 60, 25, 78.0)
	track.add_hill(25, 20, 25, 16.0)
	track.add_straight(120)
	track.add_curve(20, 18, 20, 95.0)
	track.add_curve(20, 18, 20, -95.0)
	track.add_straight(100, "turn_right", Track.LEFT)

	# big corners
	track.add_curve(25, 80, 25, 50.0)
	track.add_straight(70, "turn_left", Track.RIGHT)
	track.add_curve(20, 22, 20, -46.0)
	track.add_curve(20, 22, 20, 46.0)
	track.add_straight(90, "turn_left", Track.RIGHT)
	track.add_curve(30, 100, 30, -38.0)
	track.add_straight(110, "turn_right", Track.LEFT)
	track.add_curve(25, 70, 25, 60.0)
	track.add_hill(20, 14, 20, -12.0)
	track.add_straight(130)

	# longer straights, easier turns
	track.add_curved_hill(40, 90, 40, 180.0, -20.0)
	track.add_straight(160)
	track.add_curve(35, 85, 35, -110.0)
	track.add_straight(120)
	track.add_curve(30, 70, 30, 100.0)
	track.add_hill(25, 20, 25, 14.0)
	track.add_straight(150)
	track.add_curve(25, 55, 25, -72.0)
	track.add_straight(110, "turn_right", Track.LEFT)

	# climb with sharp turns
	track.add_curved_hill(30, 60, 30, 55.0, 26.0)
	track.add_straight(80, "turn_left", Track.RIGHT)
	track.add_curved_hill(30, 70, 30, -44.0, 24.0)
	track.add_straight(70, "turn_right", Track.LEFT)
	track.add_curve(25, 60, 25, 62.0)
	track.add_curved_hill(30, 60, 30, -58.0, 22.0)
	track.add_straight(90, "turn_right", Track.LEFT)
	track.add_curve(30, 90, 30, 48.0)
	track.add_hill(25, 18, 25, 12.0)

	# fast downhill
	track.add_curved_hill(40, 80, 40, -160.0, -28.0)
	track.add_straight(140)
	track.add_curve(20, 18, 20, 88.0)
	track.add_curve(20, 18, 20, -88.0)
	track.add_curved_hill(30, 70, 30, 115.0, -26.0)
	track.add_straight(130, "turn_left", Track.RIGHT)
	track.add_curve(30, 80, 30, -64.0)
	track.add_hill(25, 22, 25, -18.0)
	track.add_straight(170)
	track.add_curve(40, 90, 40, 190.0)
	track.add_straight(120)

	# small sections and turns
	track.add_curve(20, 20, 20, 80.0)
	track.add_curve(20, 20, 20, -80.0)
	track.add_curve(20, 20, 20, 80.0)
	track.add_straight(90, "turn_left", Track.RIGHT)
	track.add_curve(25, 75, 25, -56.0)
	track.add_hill(20, 16, 20, -14.0)
	track.add_straight(130)
	track.add_curve(30, 65, 30, 74.0)
	track.add_straight(110, "turn_left", Track.RIGHT)

	# last big turn then straight home
	track.add_curve(30, 85, 30, -54.0)
	track.add_straight(120, "turn_right", Track.LEFT)
	track.add_curve(25, 65, 25, 70.0)
	track.add_straight(100)
	track.add_hill(20, 14, 20, 14.0)
	track.add_curve(30, 60, 30, -92.0)
	track.add_straight(150, "turn_right", Track.LEFT)
	track.add_curve(25, 60, 25, 66.0)
	track.add_straight(240)
	track.add_curve(40, 70, 40, 170.0)
	track.add_straight(140)
