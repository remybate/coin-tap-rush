extends Control
class_name MapPathDrawer

var _pts: PackedVector2Array = PackedVector2Array()
var _t_anim: float = 0.0


func set_path_points(pts: PackedVector2Array) -> void:
	_pts = pts
	set_process(pts.size() >= 2)
	if pts.size() < 2:
		_t_anim = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_t_anim += delta
	queue_redraw()


func _point_at_arc_length(target: float, seg_lens: Array) -> Vector2:
	var acc: float = 0.0
	for i in range(seg_lens.size()):
		var seg: float = seg_lens[i]
		if acc + seg >= target - 0.001:
			var t: float = (target - acc) / seg if seg > 0.001 else 0.0
			return _pts[i].lerp(_pts[i + 1], clampf(t, 0.0, 1.0))
		acc += seg
	return _pts[_pts.size() - 1]


func _arc_meta() -> Dictionary:
	var seg_lens: Array = []
	var arc_len: float = 0.0
	for i in range(_pts.size() - 1):
		var l: float = _pts[i].distance_to(_pts[i + 1])
		seg_lens.append(l)
		arc_len += l
	return {"lens": seg_lens, "arc": arc_len}


func _draw() -> void:
	if _pts.size() < 2:
		return
	var meta: Dictionary = _arc_meta()
	var seg_lens: Array = meta["lens"]
	var arc_len: float = meta["arc"]

	for i in range(_pts.size() - 1):
		draw_line(_pts[i] + Vector2(3, 4), _pts[i + 1] + Vector2(3, 4), Color(0.08, 0.05, 0.04, 0.5), 60.0, true)
	for i in range(_pts.size() - 1):
		draw_line(_pts[i], _pts[i + 1], Color(0.34, 0.22, 0.1, 0.98), 52.0, true)
	for i in range(_pts.size() - 1):
		draw_line(_pts[i], _pts[i + 1], Color(0.72, 0.52, 0.18, 1), 36.0, true)
	for i in range(_pts.size() - 1):
		draw_line(_pts[i], _pts[i + 1], Color(1.0, 0.9, 0.48, 0.88), 16.0, true)

	if arc_len > 2.0:
		var spacing: float = 36.0
		var wander: float = fmod(_t_anim * 44.0, spacing)
		var n_sp: int = clampi(int(arc_len / spacing) + 3, 6, 96)
		for k in range(n_sp):
			var d: float = float(k) * spacing + wander
			if d > arc_len:
				d -= arc_len
			var pos: Vector2 = _point_at_arc_length(d, seg_lens)
			var tw: float = 0.5 + 0.5 * sin(_t_anim * 3.4 + float(k) * 0.73)
			draw_circle(pos, 3.6 * tw, Color(1, 0.96, 0.65, 0.42 * tw))
			draw_circle(pos, 1.8 * tw, Color(1, 1, 1, 0.55 * tw))
