extends Node

## Account XP, cosmetic level, titles, avatars, and rank badges — [progress] save section.
## Registered as autoload `PlayerProfile` in project.godot.

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_XP: String = "player_xp_total"
const KEY_AVATAR: String = "player_avatar_id"


func read_xp_from_cfg(cfg: ConfigFile) -> int:
	return maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_XP, 0)))


func read_avatar_from_cfg(cfg: ConfigFile) -> int:
	return clampi(int(cfg.get_value(SAVE_SECTION, KEY_AVATAR, 0)), 0, _avatar_count() - 1)


func write_avatar_on_cfg(cfg: ConfigFile, avatar_id: int) -> void:
	cfg.set_value(SAVE_SECTION, KEY_AVATAR, clampi(avatar_id, 0, _avatar_count() - 1))


func xp_cumulative_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 0
	var total: int = 0
	for i in range(1, lvl):
		total += 48 + i * 22
	return total


func player_level_from_xp(xp: int) -> int:
	var lvl: int = 1
	while xp >= xp_cumulative_for_level(lvl + 1):
		lvl += 1
		if lvl >= 999:
			break
	return lvl


func xp_progress_in_level(xp: int) -> Dictionary:
	var lv: int = player_level_from_xp(xp)
	var base: int = xp_cumulative_for_level(lv)
	var next: int = xp_cumulative_for_level(lv + 1)
	var span: int = maxi(1, next - base)
	var into: int = clampi(xp - base, 0, span)
	return {"level": lv, "into": into, "span": span, "next_total": next}


func title_for_level(lv: int) -> String:
	if lv < 5:
		return "Coin Rookie"
	if lv < 10:
		return "Treasure Hunter"
	if lv < 20:
		return "Golden Tapper"
	return "Vault Master"


func rank_badge_for_level(lv: int) -> Dictionary:
	if lv < 5:
		return {"tier": "BRONZE", "rank": "III", "accent": Color(0.72, 0.48, 0.28, 1)}
	if lv < 10:
		return {"tier": "SILVER", "rank": "II", "accent": Color(0.78, 0.82, 0.9, 1)}
	if lv < 20:
		return {"tier": "GOLD", "rank": "I", "accent": Color(1.0, 0.82, 0.28, 1)}
	return {"tier": "MYTHIC", "rank": "★", "accent": Color(0.55, 0.92, 1.0, 1)}


func _avatar_count() -> int:
	return 5


func avatar_defs() -> Array:
	return [
		{"id": 0, "emoji": "👤", "name": "Trailblazer", "unlock_lv": 1},
		{"id": 1, "emoji": "🪙", "name": "Minted", "unlock_lv": 2},
		{"id": 2, "emoji": "💎", "name": "Facet", "unlock_lv": 6},
		{"id": 3, "emoji": "✨", "name": "Gleam", "unlock_lv": 12},
		{"id": 4, "emoji": "👑", "name": "Vault Royal", "unlock_lv": 20},
	]


func avatar_emoji(avatar_id: int) -> String:
	var id: int = clampi(avatar_id, 0, _avatar_count() - 1)
	for d in avatar_defs():
		if int(d["id"]) == id:
			return str(d["emoji"])
	return "👤"


func avatar_unlocked(avatar_id: int, player_lv: int) -> bool:
	var id: int = clampi(avatar_id, 0, _avatar_count() - 1)
	for d in avatar_defs():
		if int(d["id"]) == id:
			return player_lv >= int(d["unlock_lv"])
	return false


func clamp_avatar_to_unlocked(avatar_id: int, player_lv: int) -> int:
	var id: int = clampi(avatar_id, 0, _avatar_count() - 1)
	if avatar_unlocked(id, player_lv):
		return id
	return 0


func add_xp_to_cfg(cfg: ConfigFile, amount: int) -> Dictionary:
	var prev_lv: int = player_level_from_xp(read_xp_from_cfg(cfg))
	var xp: int = read_xp_from_cfg(cfg) + maxi(0, amount)
	cfg.set_value(SAVE_SECTION, KEY_XP, xp)
	var new_lv: int = player_level_from_xp(xp)
	return {
		"xp": xp,
		"leveled_up": new_lv > prev_lv,
		"old_level": prev_lv,
		"new_level": new_lv,
		"title": title_for_level(new_lv),
	}


func grant_xp_for_level_cleared(cfg: ConfigFile, cleared_stage_level: int) -> Dictionary:
	var gain: int = 14 + clampi(cleared_stage_level, 1, 999) * 2
	return add_xp_to_cfg(cfg, gain)


func grant_xp_for_treasure_chest(cfg: ConfigFile) -> void:
	add_xp_to_cfg(cfg, 28)


func refresh_profile_button(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var cfg := ConfigFile.new()
	var av: int = 0
	var lv: int = 1
	if cfg.load(SAVE_PATH) == OK:
		av = read_avatar_from_cfg(cfg)
		lv = player_level_from_xp(read_xp_from_cfg(cfg))
		av = clamp_avatar_to_unlocked(av, lv)
	btn.icon = null
	btn.expand_icon = false
	btn.text = avatar_emoji(av)
	btn.add_theme_font_size_override("font_size", 32)
