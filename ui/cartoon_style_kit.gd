extends RefCounted
class_name CartoonStyleKit

## Shared “arcade mobile” look: thick rounded rims, deep shadows, saturated fills.

static func _shell_rounded(sb: StyleBoxFlat, corner: int) -> void:
	sb.corner_radius_top_left = corner
	sb.corner_radius_top_right = corner
	sb.corner_radius_bottom_right = corner
	sb.corner_radius_bottom_left = corner
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.52)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)


static func rank_leaderboard_row(is_you: bool, place: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	var corner: int = 22
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_right = corner
	s.corner_radius_bottom_left = corner
	s.shadow_offset = Vector2(0, 6)
	if is_you:
		s.bg_color = Color(0.38, 0.22, 0.62, 1)
		s.border_color = Color(1, 0.94, 0.48, 1)
		s.border_width_left = 5
		s.border_width_top = 5
		s.border_width_right = 5
		s.border_width_bottom = 7
		s.shadow_color = Color(1, 0.72, 0.2, 0.52)
		s.shadow_size = 20
	elif place == 1:
		s.bg_color = Color(0.42, 0.28, 0.08, 1)
		s.border_color = Color(1, 0.88, 0.35, 1)
		s.border_width_left = 6
		s.border_width_top = 6
		s.border_width_right = 6
		s.border_width_bottom = 8
		s.shadow_color = Color(1, 0.55, 0.1, 0.55)
		s.shadow_size = 22
	elif place == 2:
		s.bg_color = Color(0.22, 0.26, 0.34, 1)
		s.border_color = Color(0.92, 0.95, 1, 1)
		s.border_width_left = 5
		s.border_width_top = 5
		s.border_width_right = 5
		s.border_width_bottom = 7
		s.shadow_color = Color(0.75, 0.82, 1, 0.45)
		s.shadow_size = 18
	elif place == 3:
		s.bg_color = Color(0.32, 0.16, 0.1, 1)
		s.border_color = Color(1, 0.62, 0.38, 1)
		s.border_width_left = 5
		s.border_width_top = 5
		s.border_width_right = 5
		s.border_width_bottom = 7
		s.shadow_color = Color(1, 0.45, 0.2, 0.42)
		s.shadow_size = 18
	else:
		s.bg_color = Color(0.2, 0.16, 0.42, 1)
		s.border_color = Color(0.62, 0.72, 1, 1)
		s.border_width_left = 4
		s.border_width_top = 4
		s.border_width_right = 4
		s.border_width_bottom = 6
		s.shadow_color = Color(0.15, 0.12, 0.35, 0.5)
		s.shadow_size = 14
	return s


static func collection_card_panel(unlocked: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	_shell_rounded(s, 26)
	if unlocked:
		s.bg_color = Color(0.26, 0.14, 0.52, 0.98)
		s.border_color = Color(1, 0.9, 0.45, 1)
		s.border_width_left = 5
		s.border_width_top = 5
		s.border_width_right = 5
		s.border_width_bottom = 9
		s.shadow_color = Color(0.72, 0.38, 1, 0.55)
		s.shadow_size = 22
		s.shadow_offset = Vector2(0, 7)
	else:
		s.bg_color = Color(0.12, 0.14, 0.36, 0.97)
		s.border_color = Color(0.62, 0.72, 1, 0.95)
		s.border_width_left = 4
		s.border_width_top = 4
		s.border_width_right = 4
		s.border_width_bottom = 8
		s.shadow_color = Color(0.35, 0.42, 0.95, 0.48)
		s.shadow_size = 18
		s.shadow_offset = Vector2(0, 6)
	return s


static func trophy_milestone_panel(earned: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	_shell_rounded(s, 16)
	if earned:
		s.bg_color = Color(0.12, 0.24, 0.16, 0.97)
		s.border_color = Color(1, 0.88, 0.4, 1)
		s.shadow_color = Color(0.2, 0.55, 0.25, 0.45)
	else:
		s.bg_color = Color(0.08, 0.1, 0.2, 0.96)
		s.border_color = Color(0.55, 0.48, 0.88, 0.75)
	return s


static func event_row_panel(active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	_shell_rounded(s, 16)
	if active:
		s.bg_color = Color(0.1, 0.14, 0.28, 0.97)
		s.border_color = Color(1, 0.72, 0.32, 0.95)
	else:
		s.bg_color = Color(0.06, 0.07, 0.13, 0.95)
		s.border_color = Color(0.45, 0.48, 0.62, 0.55)
	return s


static func shop_pack_frame(accent: Color, hero: bool, pack_style: int = 0) -> StyleBoxFlat:
	## pack_style: 0 = default pack, 1 = coin tile (2×2 grid), 2 = wide store row (boosters / bundles)
	var frame := StyleBoxFlat.new()
	var bw: int = 6 if hero else 4
	if pack_style == 1:
		bw = 5 if not hero else 6
	elif pack_style == 2:
		bw = 5 if not hero else 6
	var bg: Color = accent.lerp(Color(0.04, 0.03, 0.1), 0.62 if pack_style != 0 else 0.66)
	frame.bg_color = bg
	frame.border_color = accent.lerp(Color(1, 1, 1, 1), 0.55 if pack_style != 0 else 0.48)
	frame.border_width_left = bw
	frame.border_width_top = bw
	frame.border_width_right = bw
	frame.border_width_bottom = bw + 2
	var cr: int = 26 if pack_style != 0 else 24
	frame.corner_radius_top_left = cr
	frame.corner_radius_top_right = cr
	frame.corner_radius_bottom_right = cr
	frame.corner_radius_bottom_left = cr
	frame.shadow_color = Color(accent.r, accent.g, accent.b, 0.52 if pack_style != 0 else 0.45)
	frame.shadow_size = 26 if hero else (20 if pack_style != 0 else 14)
	frame.shadow_offset = Vector2(0, 8 if pack_style != 0 else 7)
	var ml: int = 22
	var mt: int = 20
	if pack_style == 2:
		ml = 24
		mt = 22
	elif pack_style == 0:
		ml = 18
		mt = 16
	frame.content_margin_left = ml
	frame.content_margin_top = mt
	frame.content_margin_right = ml
	frame.content_margin_bottom = mt
	return frame


static func style_buy_chip(btn: Button, accent: Color, chip_style: int = 0) -> void:
	## chip_style: 0 = standard, 1 = coin tile, 2 = wide / booster XL
	var bmul: float = 1.0
	var shmul: float = 1.0
	var cr: int = 18
	if chip_style == 1:
		bmul = 1.25
		shmul = 1.35
		cr = 20
	elif chip_style == 2:
		bmul = 1.35
		shmul = 1.5
		cr = 22
	var n := StyleBoxFlat.new()
	n.bg_color = accent.lerp(Color(0.08, 0.06, 0.18), 0.12)
	n.border_color = Color(1, 0.96, 0.72, 1)
	var bw: int = int(roundf(5.0 * bmul))
	n.border_width_left = bw
	n.border_width_top = bw
	n.border_width_right = bw
	n.border_width_bottom = int(roundf(9.0 * bmul))
	n.corner_radius_top_left = cr
	n.corner_radius_top_right = cr
	n.corner_radius_bottom_right = cr
	n.corner_radius_bottom_left = cr
	n.shadow_color = Color(accent.r * 0.3, accent.g * 0.35, accent.b * 0.25, 0.55 * shmul)
	n.shadow_size = int(roundf(12.0 * shmul))
	n.shadow_offset = Vector2(0, int(roundf(5.0 * bmul)))
	var h: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	h.bg_color = accent.lerp(Color(1, 1, 1, 1), 0.35)
	h.border_color = Color(1, 1, 0.95, 1)
	var p: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	p.bg_color = accent.lerp(Color(0, 0, 0, 1), 0.22)
	p.border_width_bottom = maxi(5, int(roundf(7.0 * bmul)))
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", n)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.14, 1))
	btn.add_theme_constant_override("outline_size", 6 if chip_style >= 1 else 5)
