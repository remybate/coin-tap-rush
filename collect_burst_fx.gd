extends CPUParticles2D

## One-shot burst at tap position; lightweight radial texture (no external asset).


func _ready() -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.98, 0.75, 1), Color(1, 0.72, 0.15, 0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 24
	gt.height = 24
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1, 0.5)
	texture = gt


func burst_at(world_pos: Vector2, tint: Color) -> void:
	global_position = world_pos
	self_modulate = tint
	restart()
	emitting = true
