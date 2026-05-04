extends Control
class_name MapPathDrawer

var _pts: PackedVector2Array = PackedVector2Array()


func set_path_points(pts: PackedVector2Array) -> void:
	_pts = pts
	queue_redraw()


func _draw() -> void:
	if _pts.size() < 2:
		return
	# Wide darker bed under gold tiles (coin-garden road).
	for i in range(_pts.size() - 1):
		draw_line(_pts[i], _pts[i + 1], Color(0.32, 0.22, 0.14, 0.92), 52.0, true)
	for i in range(_pts.size() - 1):
		draw_line(_pts[i], _pts[i + 1], Color(0.48, 0.36, 0.22, 0.55), 36.0, true)
