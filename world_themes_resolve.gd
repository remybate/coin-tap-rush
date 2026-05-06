extends RefCounted

## World themes (single file). Preload as `WorldThemesResolve` from gameplay / UI scripts.
## Every `LEVELS_PER_WORLD` levels advances one slot (1-20 Treasure, 21-40 Jungle, ...).
## Add entries to `_registry()` to extend; high levels clamp to the last theme.

const LEVELS_PER_WORLD: int = 20

const DEFAULT_PLAYFIELD_TEX: String = "res://assets/backgrounds/game_bg.png"
const DEFAULT_MENU_TEX: String = "res://assets/backgrounds/home_bg.png"


static func world_slot_for_level(level: int) -> int:
	var lv: int = maxi(1, level)
	return (lv - 1) / LEVELS_PER_WORLD


static func world_index_1based(level: int) -> int:
	return world_slot_for_level(level) + 1


static func theme_for_level(level: int) -> Dictionary:
	var slot: int = world_slot_for_level(level)
	var reg: Array = _registry()
	return reg[mini(slot, reg.size() - 1)]


static func first_level_in_world_slot(slot: int) -> int:
	return slot * LEVELS_PER_WORLD + 1


static func is_world_reached(world_slot: int, furthest_unlocked_level: int) -> bool:
	return furthest_unlocked_level >= first_level_in_world_slot(world_slot)


static func unlocked_world_slot_count(furthest_unlocked_level: int) -> int:
	if furthest_unlocked_level < 1:
		return 1
	return mini(world_slot_for_level(furthest_unlocked_level) + 1, _registry().size())


static func create_vertical_readability_texture(top: Color, bottom: Color, height_px: int = 1024) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([top, bottom])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 4
	gt.height = height_px
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	return gt


static func _registry() -> Array:
	return [
		_treasure(),
		_jungle(),
		_ice(),
		_lava(),
		_space(),
		_underwater(),
	]


static func _treasure() -> Dictionary:
	return {
		"id": "treasure",
		"display_name": "Treasure Vault",
		"hud_name": "Treasure",
		"playfield_texture": DEFAULT_PLAYFIELD_TEX,
		"playfield_modulate": Color.WHITE,
		"readability_top": Color(0, 0, 0, 0),
		"readability_bottom": Color(0, 0, 0, 0),
		"floor_glow": Color(0.25, 0.55, 0.35, 0.22),
		"vignette": Color(0.02, 0, 0.08, 0.0),
		"juice_particle_color": Color(1, 0.96, 0.78, 1),
		"burst_gold_inner": Color(1.0, 0.96, 0.58, 1),
		"burst_gold_outer": Color(1.0, 0.62, 0.12, 1),
		"burst_silver_inner": Color(0.96, 0.99, 1.0, 1),
		"burst_silver_outer": Color(0.52, 0.74, 1.0, 1),
		"burst_diamond_inner": Color(0.52, 0.96, 1.0, 1),
		"burst_diamond_outer": Color(0.12, 0.42, 1.0, 1),
		"burst_bomb_inner": Color(1.0, 0.5, 0.22, 1),
		"burst_bomb_outer": Color(0.82, 0.12, 0.04, 1),
		"coin_mod_gold": Color.WHITE,
		"coin_mod_silver": Color.WHITE,
		"coin_mod_diamond": Color.WHITE,
		"coin_mod_bomb": Color.WHITE,
		"trail_gold": Color(1.0, 0.92, 0.45, 0.48),
		"trail_silver": Color(0.78, 0.92, 1.0, 0.5),
		"trail_diamond": Color(0.55, 0.98, 1.0, 0.62),
		"diamond_flash": Color(0.55, 0.92, 1.0, 0.0),
		"float_pt_gold": Color(1.0, 0.95, 0.55, 1.0),
		"float_pt_silver": Color(0.82, 0.94, 1.0, 1.0),
		"float_pt_diamond": Color(0.65, 0.98, 1.0, 1.0),
		"float_pt_outline": Color(0.12, 0.06, 0.22, 1),
		"music_path": "",
		"menu_bg_texture": DEFAULT_MENU_TEX,
		"menu_bg_modulate": Color.WHITE,
		"menu_readability_top": Color(0, 0, 0, 0),
		"menu_readability_bottom": Color(0, 0, 0, 0),
		"menu_glow_blob": Color(1, 0.82, 0.42, 0.14),
		"menu_vault_rim": Color(0.95, 0.65, 0.25, 0.06),
		"menu_floor_tint": Color(0.15, 0.55, 0.38, 0.18),
		"menu_sparkle_tint": Color(1, 1, 1, 1),
		"map_sky_colors": PackedColorArray([Color(0.55, 0.78, 1.0, 1), Color(0.42, 0.55, 0.98, 1), Color(0.55, 0.35, 0.92, 0.35)]),
		"map_sky_offsets": PackedFloat32Array([0.0, 0.45, 1.0]),
		"map_band": Color(0.28, 0.62, 0.38, 0.55),
		"map_ground": Color(0.12, 0.48, 0.28, 1),
		"map_stripe": Color(0.18, 0.58, 0.32, 1),
		"map_hill": Color(0.1, 0.42, 0.24, 0.88),
		"map_dec_coin_mod": Color(1, 0.92, 0.5, 1),
		"map_dec_gem_mod": Color(0.75, 0.92, 1.0, 1),
		"map_dec_spark_mod": Color(1, 1, 0.92, 1),
		"map_ambience_coin_tint": Color(1, 1, 0.95, 1),
		"map_ambience_spark_tint": Color(1, 0.95, 0.75, 1),
	}


static func _jungle() -> Dictionary:
	var t: Dictionary = _treasure().duplicate(true)
	t["id"] = "jungle"
	t["display_name"] = "Jungle Ruins"
	t["hud_name"] = "Jungle"
	t["playfield_modulate"] = Color(0.92, 1.0, 0.88, 1)
	t["readability_top"] = Color(0.02, 0.08, 0.02, 0.12)
	t["readability_bottom"] = Color(0.01, 0.05, 0.02, 0.38)
	t["floor_glow"] = Color(0.22, 0.62, 0.28, 0.26)
	t["vignette"] = Color(0.02, 0.06, 0.02, 0.12)
	t["juice_particle_color"] = Color(0.75, 1.0, 0.55, 1)
	t["burst_gold_inner"] = Color(1.0, 0.95, 0.45, 1)
	t["burst_gold_outer"] = Color(0.45, 0.82, 0.18, 1)
	t["burst_silver_inner"] = Color(0.85, 1.0, 0.82, 1)
	t["burst_silver_outer"] = Color(0.28, 0.72, 0.42, 1)
	t["burst_diamond_inner"] = Color(0.55, 1.0, 0.75, 1)
	t["burst_diamond_outer"] = Color(0.1, 0.55, 0.35, 1)
	t["coin_mod_gold"] = Color(1.05, 1.12, 0.9, 1)
	t["coin_mod_silver"] = Color(0.9, 1.05, 0.95, 1)
	t["coin_mod_diamond"] = Color(0.85, 1.05, 0.95, 1)
	t["trail_gold"] = Color(0.95, 1.0, 0.4, 0.5)
	t["trail_silver"] = Color(0.65, 0.95, 0.75, 0.52)
	t["trail_diamond"] = Color(0.45, 1.0, 0.72, 0.62)
	t["float_pt_gold"] = Color(1.0, 0.92, 0.45, 1)
	t["float_pt_outline"] = Color(0.04, 0.12, 0.04, 1)
	t["menu_bg_modulate"] = Color(0.9, 1.0, 0.85, 1)
	t["menu_readability_top"] = Color(0.02, 0.06, 0.02, 0.1)
	t["menu_readability_bottom"] = Color(0.01, 0.05, 0.02, 0.28)
	t["menu_glow_blob"] = Color(0.45, 0.95, 0.35, 0.16)
	t["menu_vault_rim"] = Color(0.35, 0.75, 0.25, 0.08)
	t["menu_floor_tint"] = Color(0.12, 0.45, 0.22, 0.22)
	t["menu_sparkle_tint"] = Color(0.75, 1.0, 0.55, 1)
	t["map_sky_colors"] = PackedColorArray([Color(0.35, 0.72, 0.48, 1), Color(0.18, 0.52, 0.38, 1), Color(0.08, 0.32, 0.22, 0.45)])
	t["map_band"] = Color(0.22, 0.55, 0.28, 0.58)
	t["map_ground"] = Color(0.08, 0.35, 0.18, 1)
	t["map_stripe"] = Color(0.12, 0.48, 0.22, 1)
	t["map_hill"] = Color(0.06, 0.38, 0.16, 0.9)
	t["map_dec_coin_mod"] = Color(0.95, 1.0, 0.55, 1)
	t["map_dec_gem_mod"] = Color(0.55, 1.0, 0.75, 1)
	t["map_dec_spark_mod"] = Color(0.75, 1.0, 0.65, 1)
	t["map_ambience_coin_tint"] = Color(0.85, 1.0, 0.65, 1)
	t["map_ambience_spark_tint"] = Color(0.65, 1.0, 0.75, 1)
	return t


static func _ice() -> Dictionary:
	var t: Dictionary = _treasure().duplicate(true)
	t["id"] = "ice"
	t["display_name"] = "Ice Frontier"
	t["hud_name"] = "Ice"
	t["playfield_modulate"] = Color(0.88, 0.95, 1.05, 1)
	t["readability_top"] = Color(0.05, 0.12, 0.22, 0.15)
	t["readability_bottom"] = Color(0.02, 0.06, 0.14, 0.42)
	t["floor_glow"] = Color(0.45, 0.75, 0.95, 0.22)
	t["vignette"] = Color(0.02, 0.05, 0.12, 0.14)
	t["juice_particle_color"] = Color(0.82, 0.95, 1.0, 1)
	t["burst_gold_inner"] = Color(1.0, 0.98, 0.88, 1)
	t["burst_gold_outer"] = Color(0.45, 0.78, 1.0, 1)
	t["burst_silver_inner"] = Color(0.95, 1.0, 1.0, 1)
	t["burst_silver_outer"] = Color(0.55, 0.82, 1.0, 1)
	t["burst_diamond_inner"] = Color(0.75, 0.98, 1.0, 1)
	t["burst_diamond_outer"] = Color(0.2, 0.55, 1.0, 1)
	t["coin_mod_gold"] = Color(0.95, 1.02, 1.08, 1)
	t["coin_mod_silver"] = Color(0.92, 0.98, 1.05, 1)
	t["coin_mod_diamond"] = Color(0.88, 0.98, 1.05, 1)
	t["trail_gold"] = Color(0.92, 0.98, 1.0, 0.5)
	t["trail_silver"] = Color(0.75, 0.92, 1.0, 0.55)
	t["trail_diamond"] = Color(0.55, 0.92, 1.0, 0.65)
	t["diamond_flash"] = Color(0.75, 0.95, 1.0, 0.0)
	t["float_pt_gold"] = Color(0.92, 0.98, 1.0, 1)
	t["float_pt_outline"] = Color(0.05, 0.08, 0.18, 1)
	t["menu_bg_modulate"] = Color(0.88, 0.95, 1.05, 1)
	t["menu_readability_top"] = Color(0.04, 0.1, 0.18, 0.12)
	t["menu_readability_bottom"] = Color(0.02, 0.05, 0.12, 0.32)
	t["menu_glow_blob"] = Color(0.55, 0.85, 1.0, 0.18)
	t["menu_vault_rim"] = Color(0.45, 0.72, 1.0, 0.08)
	t["menu_floor_tint"] = Color(0.2, 0.45, 0.72, 0.2)
	t["menu_sparkle_tint"] = Color(0.75, 0.92, 1.0, 1)
	t["map_sky_colors"] = PackedColorArray([Color(0.72, 0.88, 1.0, 1), Color(0.45, 0.68, 0.95, 1), Color(0.25, 0.45, 0.78, 0.4)])
	t["map_band"] = Color(0.55, 0.78, 0.95, 0.5)
	t["map_ground"] = Color(0.35, 0.58, 0.82, 1)
	t["map_stripe"] = Color(0.62, 0.82, 0.98, 1)
	t["map_hill"] = Color(0.42, 0.68, 0.92, 0.88)
	t["map_dec_coin_mod"] = Color(0.9, 0.96, 1.0, 1)
	t["map_dec_gem_mod"] = Color(0.65, 0.88, 1.0, 1)
	t["map_dec_spark_mod"] = Color(0.95, 1.0, 1.0, 1)
	t["map_ambience_coin_tint"] = Color(0.85, 0.95, 1.0, 1)
	t["map_ambience_spark_tint"] = Color(0.8, 0.95, 1.0, 1)
	return t


static func _lava() -> Dictionary:
	var t: Dictionary = _treasure().duplicate(true)
	t["id"] = "lava"
	t["display_name"] = "Magma Caverns"
	t["hud_name"] = "Lava"
	t["playfield_modulate"] = Color(1.08, 0.82, 0.72, 1)
	t["readability_top"] = Color(0.12, 0.02, 0.02, 0.22)
	t["readability_bottom"] = Color(0.08, 0.01, 0.0, 0.48)
	t["floor_glow"] = Color(0.95, 0.35, 0.12, 0.28)
	t["vignette"] = Color(0.12, 0.02, 0.0, 0.2)
	t["juice_particle_color"] = Color(1.0, 0.65, 0.25, 1)
	t["burst_gold_inner"] = Color(1.0, 0.92, 0.45, 1)
	t["burst_gold_outer"] = Color(1.0, 0.35, 0.08, 1)
	t["burst_silver_inner"] = Color(1.0, 0.85, 0.72, 1)
	t["burst_silver_outer"] = Color(0.95, 0.42, 0.15, 1)
	t["burst_diamond_inner"] = Color(1.0, 0.75, 0.45, 1)
	t["burst_diamond_outer"] = Color(0.85, 0.2, 0.05, 1)
	t["burst_bomb_inner"] = Color(1.0, 0.35, 0.1, 1)
	t["burst_bomb_outer"] = Color(0.5, 0.05, 0.02, 1)
	t["coin_mod_gold"] = Color(1.12, 0.95, 0.85, 1)
	t["coin_mod_silver"] = Color(1.05, 0.88, 0.78, 1)
	t["coin_mod_diamond"] = Color(1.08, 0.82, 0.72, 1)
	t["coin_mod_bomb"] = Color(1.05, 0.9, 0.88, 1)
	t["trail_gold"] = Color(1.0, 0.72, 0.28, 0.55)
	t["trail_silver"] = Color(1.0, 0.65, 0.45, 0.52)
	t["trail_diamond"] = Color(1.0, 0.55, 0.35, 0.62)
	t["float_pt_outline"] = Color(0.18, 0.04, 0.02, 1)
	t["menu_bg_modulate"] = Color(1.05, 0.82, 0.72, 1)
	t["menu_readability_top"] = Color(0.1, 0.02, 0.02, 0.18)
	t["menu_readability_bottom"] = Color(0.06, 0.01, 0.0, 0.4)
	t["menu_glow_blob"] = Color(1.0, 0.45, 0.15, 0.2)
	t["menu_vault_rim"] = Color(1.0, 0.35, 0.1, 0.1)
	t["menu_floor_tint"] = Color(0.55, 0.15, 0.08, 0.28)
	t["menu_sparkle_tint"] = Color(1.0, 0.72, 0.35, 1)
	t["map_sky_colors"] = PackedColorArray([Color(0.45, 0.12, 0.08, 1), Color(0.32, 0.08, 0.05, 1), Color(0.18, 0.04, 0.02, 0.55)])
	t["map_band"] = Color(0.85, 0.28, 0.08, 0.62)
	t["map_ground"] = Color(0.28, 0.08, 0.04, 1)
	t["map_stripe"] = Color(0.72, 0.22, 0.06, 1)
	t["map_hill"] = Color(0.42, 0.1, 0.04, 0.9)
	t["map_dec_coin_mod"] = Color(1.0, 0.85, 0.45, 1)
	t["map_dec_gem_mod"] = Color(1.0, 0.65, 0.45, 1)
	t["map_dec_spark_mod"] = Color(1.0, 0.75, 0.35, 1)
	t["map_ambience_coin_tint"] = Color(1.0, 0.82, 0.55, 1)
	t["map_ambience_spark_tint"] = Color(1.0, 0.65, 0.35, 1)
	return t


static func _space() -> Dictionary:
	var t: Dictionary = _treasure().duplicate(true)
	t["id"] = "space"
	t["display_name"] = "Star Belt"
	t["hud_name"] = "Space"
	t["playfield_modulate"] = Color(0.82, 0.88, 1.05, 1)
	t["readability_top"] = Color(0.02, 0.02, 0.12, 0.25)
	t["readability_bottom"] = Color(0.01, 0.0, 0.08, 0.52)
	t["floor_glow"] = Color(0.35, 0.22, 0.72, 0.26)
	t["vignette"] = Color(0.04, 0.0, 0.12, 0.22)
	t["juice_particle_color"] = Color(0.72, 0.88, 1.0, 1)
	t["burst_gold_inner"] = Color(1.0, 0.95, 0.65, 1)
	t["burst_gold_outer"] = Color(0.55, 0.35, 1.0, 1)
	t["burst_silver_inner"] = Color(0.92, 0.95, 1.0, 1)
	t["burst_silver_outer"] = Color(0.45, 0.55, 1.0, 1)
	t["burst_diamond_inner"] = Color(0.65, 0.85, 1.0, 1)
	t["burst_diamond_outer"] = Color(0.35, 0.15, 0.95, 1)
	t["coin_mod_gold"] = Color(1.02, 0.95, 1.05, 1)
	t["coin_mod_silver"] = Color(0.92, 0.95, 1.05, 1)
	t["coin_mod_diamond"] = Color(0.88, 0.92, 1.08, 1)
	t["trail_gold"] = Color(1.0, 0.88, 0.55, 0.52)
	t["trail_silver"] = Color(0.78, 0.82, 1.0, 0.55)
	t["trail_diamond"] = Color(0.62, 0.75, 1.0, 0.65)
	t["diamond_flash"] = Color(0.65, 0.55, 1.0, 0.0)
	t["float_pt_diamond"] = Color(0.78, 0.88, 1.0, 1)
	t["float_pt_outline"] = Color(0.06, 0.04, 0.18, 1)
	t["menu_bg_modulate"] = Color(0.78, 0.82, 1.05, 1)
	t["menu_readability_top"] = Color(0.03, 0.02, 0.12, 0.2)
	t["menu_readability_bottom"] = Color(0.01, 0.0, 0.08, 0.45)
	t["menu_glow_blob"] = Color(0.55, 0.35, 1.0, 0.2)
	t["menu_vault_rim"] = Color(0.45, 0.28, 0.92, 0.1)
	t["menu_floor_tint"] = Color(0.22, 0.12, 0.55, 0.26)
	t["menu_sparkle_tint"] = Color(0.75, 0.82, 1.0, 1)
	t["map_sky_colors"] = PackedColorArray([Color(0.12, 0.08, 0.38, 1), Color(0.06, 0.05, 0.22, 1), Color(0.02, 0.02, 0.12, 0.65)])
	t["map_band"] = Color(0.35, 0.22, 0.62, 0.55)
	t["map_ground"] = Color(0.08, 0.05, 0.22, 1)
	t["map_stripe"] = Color(0.22, 0.15, 0.55, 1)
	t["map_hill"] = Color(0.12, 0.08, 0.38, 0.88)
	t["map_dec_coin_mod"] = Color(1.0, 0.92, 0.75, 1)
	t["map_dec_gem_mod"] = Color(0.72, 0.82, 1.0, 1)
	t["map_dec_spark_mod"] = Color(0.95, 0.92, 1.0, 1)
	t["map_ambience_coin_tint"] = Color(0.92, 0.88, 1.0, 1)
	t["map_ambience_spark_tint"] = Color(0.82, 0.88, 1.0, 1)
	return t


static func _underwater() -> Dictionary:
	var t: Dictionary = _treasure().duplicate(true)
	t["id"] = "underwater"
	t["display_name"] = "Abyssal Reef"
	t["hud_name"] = "Deep Sea"
	t["playfield_modulate"] = Color(0.78, 0.95, 1.05, 1)
	t["readability_top"] = Color(0.02, 0.08, 0.14, 0.2)
	t["readability_bottom"] = Color(0.0, 0.05, 0.12, 0.48)
	t["floor_glow"] = Color(0.15, 0.55, 0.62, 0.3)
	t["vignette"] = Color(0.0, 0.05, 0.12, 0.18)
	t["juice_particle_color"] = Color(0.55, 0.92, 1.0, 1)
	t["burst_gold_inner"] = Color(1.0, 0.95, 0.65, 1)
	t["burst_gold_outer"] = Color(0.25, 0.75, 0.95, 1)
	t["burst_silver_inner"] = Color(0.82, 0.98, 1.0, 1)
	t["burst_silver_outer"] = Color(0.25, 0.65, 0.92, 1)
	t["burst_diamond_inner"] = Color(0.55, 0.95, 1.0, 1)
	t["burst_diamond_outer"] = Color(0.12, 0.45, 0.88, 1)
	t["coin_mod_gold"] = Color(0.92, 1.02, 1.05, 1)
	t["coin_mod_silver"] = Color(0.85, 0.98, 1.05, 1)
	t["coin_mod_diamond"] = Color(0.78, 0.98, 1.08, 1)
	t["trail_gold"] = Color(0.95, 0.98, 0.55, 0.5)
	t["trail_silver"] = Color(0.55, 0.88, 1.0, 0.55)
	t["trail_diamond"] = Color(0.45, 0.92, 1.0, 0.65)
	t["float_pt_outline"] = Color(0.02, 0.08, 0.14, 1)
	t["menu_bg_modulate"] = Color(0.78, 0.95, 1.02, 1)
	t["menu_readability_top"] = Color(0.02, 0.08, 0.14, 0.16)
	t["menu_readability_bottom"] = Color(0.0, 0.05, 0.12, 0.38)
	t["menu_glow_blob"] = Color(0.25, 0.75, 0.92, 0.18)
	t["menu_vault_rim"] = Color(0.2, 0.62, 0.85, 0.1)
	t["menu_floor_tint"] = Color(0.08, 0.38, 0.52, 0.26)
	t["menu_sparkle_tint"] = Color(0.55, 0.92, 1.0, 1)
	t["map_sky_colors"] = PackedColorArray([Color(0.12, 0.45, 0.72, 1), Color(0.08, 0.32, 0.55, 1), Color(0.04, 0.18, 0.38, 0.5)])
	t["map_band"] = Color(0.08, 0.48, 0.62, 0.55)
	t["map_ground"] = Color(0.04, 0.22, 0.38, 1)
	t["map_stripe"] = Color(0.06, 0.38, 0.52, 1)
	t["map_hill"] = Color(0.05, 0.28, 0.42, 0.88)
	t["map_dec_coin_mod"] = Color(0.85, 0.95, 1.0, 1)
	t["map_dec_gem_mod"] = Color(0.55, 0.88, 1.0, 1)
	t["map_dec_spark_mod"] = Color(0.72, 0.95, 1.0, 1)
	t["map_ambience_coin_tint"] = Color(0.72, 0.95, 1.0, 1)
	t["map_ambience_spark_tint"] = Color(0.55, 0.92, 1.0, 1)
	return t
