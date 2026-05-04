extends Control
class_name LevelMapAmbience

## Subtle floating coins + soft sparkle breathing (single _process).

var _float_nodes: Array[TextureRect] = []
var _float_base: Array[Vector2] = []
var _float_phase: Array[float] = []
var _spark_nodes: Array[TextureRect] = []
var _spark_phase: Array[float] = []
var _t: float = 0.0


func clear_all() -> void:
	for c in get_children():
		c.queue_free()
	_float_nodes.clear()
	_float_base.clear()
	_float_phase.clear()
	_spark_nodes.clear()
	_spark_phase.clear()
	set_process(false)


func build(map_w: float, map_h: float, curve_points: PackedVector2Array) -> void:
	clear_all()
	var coin_tex: Texture2D = load("res://ui/map_art/coin_small.svg") as Texture2D
	var spark_tex: Texture2D = load("res://ui/map_art/sparkle.svg") as Texture2D
	if coin_tex == null or spark_tex == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(map_w), int(map_h))) + curve_points.size()

	var n_float: int = 6
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
		tr.modulate = Color(1, 1, 0.95, rng.randf_range(0.38, 0.58))
		add_child(tr)
		_float_nodes.append(tr)
		_float_base.append(Vector2(x, y))
		_float_phase.append(rng.randf() * TAU)

	var n_spark: int = 8
	for j in range(n_spark):
		var sp := TextureRect.new()
		sp.texture = spark_tex
		sp.custom_minimum_size = Vector2(16, 16)
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.position = Vector2(rng.randf_range(6, map_w - 24), rng.randf_range(20, map_h - 40))
		sp.modulate = Color(1, 1, 1, 0.26)
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
		# Slow, small figure-eight–style drift (no cumulative error)
		tr.position.x = base.x + sin(_t * 0.85 + ph) * 5.0
		tr.position.y = base.y + sin(_t * 1.05 + ph * 1.03 + 0.7) * 7.0
		i += 1

	var j := 0
	while j < _spark_nodes.size():
		var sp: TextureRect = _spark_nodes[j]
		if not is_instance_valid(sp):
			_spark_nodes.remove_at(j)
			_spark_phase.remove_at(j)
			continue
		var a: float = 0.2 + 0.14 * sin(_t * 1.05 + _spark_phase[j])
		sp.modulate.a = clampf(a, 0.14, 0.36)
		j += 1
