extends CPUParticles2D

## One-shot burst at tap position; lightweight radial texture (no external asset).


func _ready() -> void:
	_ensure_radial_texture()


func _ensure_radial_texture() -> void:
	if texture != null:
		return
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.98, 0.75, 1), Color(1, 0.72, 0.15, 0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 28
	gt.height = 28
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	texture = gt


func burst_at(world_pos: Vector2, inner: Color, outer: Color, burst_scale: float = 1.0) -> void:
	_ensure_radial_texture()
	global_position = world_pos
	var g := Gradient.new()
	g.colors = PackedColorArray([inner, outer])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var gt: GradientTexture2D = texture as GradientTexture2D
	if gt == null:
		gt = GradientTexture2D.new()
		gt.width = 28
		gt.height = 28
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1, 0.5)
		texture = gt
	gt.gradient = g

	var sc: float = clampf(burst_scale, 0.65, 1.45)
	amount = clampi(int(52.0 * sc), 36, 86)
	lifetime = lerpf(0.48, 0.68, sc * 0.5)
	explosiveness = 0.88
	spread = lerpf(142.0, 178.0, sc - 0.65)
	initial_velocity_min = 95.0 * sc
	initial_velocity_max = 340.0 * sc
	scale_amount_min = 1.85 * sc
	scale_amount_max = 6.2 * sc
	direction = Vector2(0.0, -1.0)
	gravity = Vector2(0.0, 280.0)
	self_modulate = Color.WHITE
	restart()
	emitting = true


## Second, wider sparkle pass for trails / richness (visual only).
func burst_sparkle_addon(world_pos: Vector2, inner: Color, outer: Color, burst_scale: float = 1.0) -> void:
	_ensure_radial_texture()
	global_position = world_pos
	var g := Gradient.new()
	var mid: Color = inner.lerp(outer, 0.45)
	mid.a = 0.92
	g.colors = PackedColorArray([Color(inner.r, inner.g, inner.b, 0.15), mid, Color(outer.r, outer.g, outer.b, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var gt: GradientTexture2D = texture as GradientTexture2D
	if gt == null:
		return
	gt.gradient = g
	var sc: float = clampf(burst_scale, 0.55, 1.5)
	amount = clampi(int(44.0 * sc), 32, 78)
	lifetime = lerpf(0.55, 0.82, sc * 0.45)
	explosiveness = 0.52
	spread = 200.0
	initial_velocity_min = 40.0 * sc
	initial_velocity_max = 220.0 * sc
	scale_amount_min = 0.9 * sc
	scale_amount_max = 3.8 * sc
	direction = Vector2(0.0, -1.0)
	gravity = Vector2(0.0, 120.0)
	self_modulate = Color(1.05, 1.05, 1.12, 1.0)
	restart()
	emitting = true
