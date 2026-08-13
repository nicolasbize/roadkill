class_name JapanTrack
extends TrackDefinition

# Japan has good variety of straights / turns / climb / descents

func lay_out(track: Track) -> void:
	# fast start
	track.add_straight(200)
	track.add_curve(45, 110, 45, 260.0)
	track.add_straight(180)
	track.add_curved_hill(40, 90, 40, -220.0, 30.0)
	track.add_straight(150)
	track.add_hill(25, 18, 25, -18.0)
	track.add_curve(40, 80, 40, 200.0)
	track.add_straight(220)
	track.add_curve(35, 70, 35, -160.0)
	track.add_straight(160, "turn_right", Track.LEFT)

	# sharp turns for a bit
	track.add_curve(25, 45, 25, 62.0)
	track.add_straight(70, "turn_left", Track.RIGHT)
	track.add_curve(20, 18, 20, -48.0)
	track.add_straight(90)
	track.add_curve(20, 20, 20, 70.0)
	track.add_curve(20, 20, 20, -70.0)
	track.add_curved_hill(25, 50, 25, 85.0, -14.0)
	track.add_straight(110, "turn_left", Track.RIGHT)
	track.add_curve(30, 55, 30, -55.0)
	track.add_straight(80)
	track.add_curve(25, 40, 25, 95.0)
	track.add_curve(15, 35, 15, 52.0)
	track.add_straight(120, "turn_left", Track.RIGHT)
	track.add_curve(25, 40, 25, -46.0)
	track.add_straight(130)

	# climb with long corners
	track.add_curved_hill(30, 65, 30, 120.0, 32.0)
	track.add_straight(80, "turn_left", Track.RIGHT)
	track.add_curved_hill(25, 50, 25, -58.0, 28.0)
	track.add_hill(24, 16, 24, 20.0)
	track.add_curve(25, 45, 25, 66.0)
	track.add_straight(100)
	track.add_curved_hill(25, 55, 25, -90.0, 28.0)
	track.add_straight(120)

	# long corners, can still go fast
	track.add_curve(20, 18, 20, 78.0)
	track.add_curve(20, 18, 20, -78.0)
	track.add_curve(20, 18, 20, 78.0)
	track.add_curve(20, 18, 20, -78.0)
	track.add_straight(90, "turn_right", Track.LEFT)
	track.add_curve(25, 50, 25, 60.0)
	track.add_hill(20, 12, 20, -16.0)
	track.add_curve(20, 18, 20, -54.0)
	track.add_straight(110)

	# downhill with sharper corners
	track.add_straight(50, "turn_left", Track.RIGHT)
	track.add_curved_hill(25, 55, 25, -44.0, -16.0)
	track.add_straight(50, "turn_right", Track.LEFT)
	track.add_curved_hill(25, 50, 25, 42.0, -14.0)
	track.add_straight(45, "turn_left", Track.RIGHT)
	track.add_curved_hill(25, 55, 25, -46.0, -16.0)
	track.add_curve(20, 26, 20, 90.0)
	track.add_curved_hill(25, 50, 25, -50.0, -14.0)
	track.add_hill(15, 10, 15, -10.0)
	track.add_curved_hill(25, 50, 25, -48.0, -18.0)
	track.add_straight(80)
	track.add_curved_hill(30, 60, 30, 130.0, -22.0)

	# open road again to finish
	track.add_straight(140)
	track.add_curve(25, 50, 25, -68.0)
	track.add_straight(120, "turn_right", Track.LEFT)
	track.add_curve(30, 55, 30, 58.0)
	track.add_hill(24, 16, 24, 20.0)
	track.add_straight(180)
	track.add_curve(40, 80, 40, 190.0)
	track.add_straight(280)
