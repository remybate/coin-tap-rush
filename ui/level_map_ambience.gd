extends Control
class_name LevelMapAmbience

## Floating coins, path sparkles, and soft star twinkle (single _process).

var _float_nodes: Array[TextureRect] = []
var _float_base: Array[Vector2] = []
var _float_phase: Array[float] = []
var _path_nodes: Array[TextureRect] = []
var _path_base: Array[Vector2] = []
var _path_phase: Array[float] = []
var _spark_nodes: Array[TextureRect] = []
var _spark_phase: Array[float] = []
var _t: float = 0.0


func clear_all() -> void:
	for c in get_children():
		c.queue_free()
	_float_nodes.clear()
	_float_base.clear()
	_float_phase.clear()
	_path_nodes.clear()
	_path_base.clear()
	_path_phase.clear()
	_spark_nodes.clear()
	_spark_phase.clear()
	set_process(false)


func _polyline_length(pts: PackedVector2Array) -> float:
	var L: float = 0.0
	for i in range(pts.size() - 1):
		L += pts[i].distance_to(pts[i + 1])
	return L


func _point_on_polyline(pts: PackedVector2Array, dist: float) -> Vector2:
	if pts.size() < 2:
		return pts[0] if pts.size() > 0 else Vector2.ZERO
	var acc: float = 0.0
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var seg: float = a.distance_to(b)
		if acc + seg >= dist - 0.001:
			var t: float = (dist - acc) / seg if seg > 0.001 else 0.0
			return a.lerp(b, clampf(t, 0.0, 1.0))
		acc += seg
	return pts[pts.size() - 1]


func build(map_w: float, map_h: float, anchor_pts: PackedVector2Array, path_polyline: PackedVector2Array, ambient_coin_tint: Color = Color.WHITE, ambient_spark_tint: Color = Color.WHITE) -> void:
	clear_all()
	var coin_tex: Texture2D = load("res://ui/map_art/coin_small.svg") as Texture2D
	var spark_tex: Texture2D = load("res://ui/map_art/sparkle.svg") as Texture2D
	if coin_tex == null or spark_tex == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(map_w), int(map_h))) + anchor_pts.size()

	var n_float: int = 8
	for i in range(n_float):
		var tr := TextureRect.new()
		tr.texture = coin_tex
		tr.custom_minimum_size = Vector2(22, 22)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var x: float = clampf(map_w * 0.5 + side * rng.randf_range(100, map_w * 0.42), 8, map_w - 36)
		var y: float = rng.randf_range(40, map_h - 80)
		tr.position = Vector2(x, y)
		var a0: float = rng.randf_range(0.38, 0.58)
		tr.modulate = Color(ambient_coin_tint.r, ambient_coin_tint.g, ambient_coin_tint.b, a0)
		add_child(tr)
		_float_nodes.append(tr)
		_float_base.append(Vector2(x, y))
		_float_phase.append(rng.randf() * TAU)

	var plen: float = _polyline_length(path_polyline)
	if plen > 4.0:
		var spacing: float = rng.randf_range(52.0, 78.0)
		var d: float = rng.randf() * spacing
		while d < plen - 2.0:
			var base_p: Vector2 = _point_on_polyline(path_polyline, d)
			var side2: float = -1.0 if rng.randf() < 0.5 else 1.0
			var off := Vector2(side2 * rng.randf_range(10, 26), rng.randf_range(-5, 7))
			var tr2 := TextureRect.new()
			tr2.texture = spark_tex
			tr2.custom_minimum_size = Vector2(14, 14)
			tr2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr2.position = base_p + off - Vector2(7, 7)
			var a1: float = rng.randf_range(0.35, 0.55)
			tr2.modulate = Color(ambient_spark_tint.r, ambient_spark_tint.g, ambient_spark_tint.b, a1)
			add_child(tr2)
			_path_nodes.append(tr2)
			_path_base.append(base_p + off)
			_path_phase.append(rng.randf() * TAU)
			d += spacing

	var n_spark: int = 14
	for j in range(n_spark):
		var sp := TextureRect.new()
		sp.texture = spark_tex
		sp.custom_minimum_size = Vector2(14 + (j % 3) * 2, 14 + (j % 3) * 2)
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.position = Vector2(rng.randf_range(6, map_w - 24), rng.randf_range(20, map_h - 40))
		sp.modulate = Color(ambient_spark_tint.r, ambient_spark_tint.g, ambient_spark_tint.b, 0.22)
		add_child(sp)
		_spark_nodes.append(sp)
		_spark_phase.append(rng.randf() * TAU)

	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var i := 0
	while i < _float_nodes.size():
		var tr: TextureRect = _float_nodes[i]
		if not is_instance_valid(tr):
			_float_nodes.remove_at(i)
			_float_base.remove_at(i)
			_float_phase.remove_at(i)
			continue
		var base: Vector2 = _float_base[i]
		var ph: float = _float_phase[i]
		tr.position.x = base.x + sin(_t * 0.85 + ph) * 5.0
		tr.position.y = base.y + sin(_t * 1.05 + ph * 1.03 + 0.7) * 7.0
		i += 1

	var pi := 0
	while pi < _path_nodes.size():
		var pr: TextureRect = _path_nodes[pi]
		if not is_instance_valid(pr):
			_path_nodes.remove_at(pi)
			_path_base.remove_at(pi)
			_path_phase.remove_at(pi)
			continue
		var b2: Vector2 = _path_base[pi]
		var ph2: float = _path_phase[pi]
		pr.position.x = b2.x + sin(_t * 1.25 + ph2) * 3.0
		pr.position.y = b2.y + sin(_t * 1.55 + ph2 * 0.9) * 3.5
		var a2: float = 0.32 + 0.22 * sin(_t * 2.1 + ph2)
		pr.modulate.a = clampf(a2, 0.2, 0.62)
		pi += 1

	var j := 0
	while j < _spark_nodes.size():
		var sp: TextureRect = _spark_nodes[j]
		if not is_instance_valid(sp):
			_spark_nodes.remove_at(j)
			_spark_phase.remove_at(j)
			continue
		var a: float = 0.18 + 0.16 * sin(_t * 1.15 + _spark_phase[j])
		sp.modulate.a = clampf(a, 0.12, 0.42)
		j += 1
