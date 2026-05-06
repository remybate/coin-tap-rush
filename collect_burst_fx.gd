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
	amount = clampi(int(36.0 * sc), 28, 58)
	lifetime = lerpf(0.42, 0.58, sc * 0.5)
	explosiveness = 0.88
	spread = lerpf(138.0, 168.0, sc - 0.65)
	initial_velocity_min = 80.0 * sc
	initial_velocity_max = 300.0 * sc
	scale_amount_min = 1.6 * sc
	scale_amount_max = 4.8 * sc
	self_modulate = Color.WHITE
	restart()
	emitting = true
