class_name LabelUtils

static func get_ordinal(place: int) -> String:
	var suffix := "th"
	if place % 100 < 11 or place % 100 > 13:
		match place % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return str(place) + suffix

static func get_time(time: int) -> String:
	var time_secs := floori(int(time / 1000.0))
	var minutes := floori(int(time_secs / 60.0))
	var secs := time_secs - minutes * 60
	return "%d:%02d" % [minutes, secs]
