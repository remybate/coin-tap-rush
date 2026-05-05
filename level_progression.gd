extends RefCounted
class_name LevelProgression

## Procedural difficulty for Coin Tap Rush (levels 1 … 5000+).
## Uses smooth formulas + a mild "tier" bump every 10 levels so challenge escalates without spikes.

const MAX_LEVEL: int = 9999
const ABS_MAX_FALL: float = 900.0
const ABS_MIN_SPAWN_INTERVAL: float = 0.35
const ABS_MAX_OBJECTS: int = 12


## Main entry: one dictionary per level for gameplay + UI.
static func get_level_config(level: int) -> Dictionary:
	var lv: int = clampi(level, 1, MAX_LEVEL)
	var tier: int = (lv - 1) / 10
	# Gentle per-tier multiplier (every 10 levels): ~1.5% speed pressure, stacks slowly.
	var tier_mul: float = 1.0 + float(tier) * 0.015

	# --- Core formulas (user-requested shape) ---
	# fall_speed: linear ramp, capped so late game stays playable.
	var fall_speed: float = clampf((120.0 + float(lv) * 3.0) * tier_mul, 120.0, ABS_MAX_FALL)
	# spawn_interval: lower = denser pressure; clamp so we never spam infinitely fast.
	var spawn_interval: float = clampf(1.5 - float(lv) * 0.01, ABS_MIN_SPAWN_INTERVAL, 1.5)
	# max_objects: stair-step every 10 levels, cap 12 (matches practical playfield).
	var max_objects: int = clampi(1 + int(floor(float(lv) / 10.0)), 1, ABS_MAX_OBJECTS)
	# bomb_chance: 0 until level 21, then ramps.
	var bomb_chance: float = 0.0
	if lv >= 21:
		bomb_chance = clampf((float(lv) - 20.0) * 0.003, 0.0, 0.35)
	# diamond_chance: meaningful gems once diamonds are "unlocked" at 31+.
	var diamond_chance: float = 0.0
	if lv >= 31:
		diamond_chance = clampf(0.05 + float(lv) * 0.0005, 0.05, 0.20)
	# target_score: points (session score) needed this level, beyond floor at level start.
	var target_score: int = maxi(20 + lv * 5, 25)
	# target_coins: gleam "coin" pickups (base_pts sum) OR with score — either can finish the level.
	var target_coins: int = clampi(10 + lv * 3, 8, 5000)
	# time_limit: 0 = none. Soft pressure at very high ranks only (keeps early game calm).
	var time_limit: float = 0.0
	if lv >= 120:
		time_limit = clampf(360.0 - float(lv - 120) * 0.04, 90.0, 360.0)

	# Milestone: "special gold" bias from 50+ (more gold vs silver in the non-bomb/diamond bucket).
	var gold_bias: float = 1.0
	if lv >= 50:
		gold_bias = clampf(1.0 + float(lv - 50) * 0.002, 1.0, 1.35)

	var difficulty_name: String = _difficulty_name_for(lv, tier)

	return {
		"level": lv,
		"fall_speed": fall_speed,
		"spawn_interval": spawn_interval,
		"max_objects": max_objects,
		"bomb_chance": bomb_chance,
		"diamond_chance": diamond_chance,
		"silver_chance": _silver_share(lv, tier),
		"gold_bias": gold_bias,
		"target_score": target_score,
		"target_coins": target_coins,
		"time_limit": time_limit,
		"available_boosters": _booster_flags(lv),
		"difficulty_name": difficulty_name,
	}


static func _silver_share(lv: int, tier: int) -> float:
	# Levels 1–10: only “normal” gold coins (no big silver) per design brief.
	if lv <= 10:
		return 0.0
	# Slightly less silver room as diamonds/bombs grow; clamp for stable normalization.
	return clampf(0.38 - float(tier) * 0.012, 0.22, 0.38)


static func _difficulty_name_for(lv: int, tier: int) -> String:
	if lv <= 10:
		return "River Shallows"
	if lv <= 20:
		return "Sunlit Drift"
	if lv <= 30:
		return "Rocky Riffle"
	if lv <= 40:
		return "Crystal Rapids"
	if lv <= 50:
		return "Twin Torrents"
	if tier < 20:
		return "Deep Channel %d" % (tier + 1)
	if tier < 50:
		return "Abyss Run %d" % (tier + 1)
	if tier < 100:
		return "Tempest Lane %d" % (tier + 1)
	return "Mythic Surge %d" % (tier + 1)


static func _booster_flags(lv: int) -> Dictionary:
	return {
		"pregame_hourglass": lv >= 10,
		"ingame_magnet": lv >= 20,
		"ingame_shield": lv >= 30,
		"ingame_freeze": lv >= 40,
		"special_gold": lv >= 50,
	}


## Sum of target_score for levels [1 .. last_level] — used to reconstruct session score when picking a map level.
static func get_cumulative_score_through_level(last_level: int) -> int:
	var last: int = clampi(last_level, 0, MAX_LEVEL)
	var sum: int = 0
	for i in range(1, last + 1):
		sum += int(get_level_config(i).target_score)
	return sum


static func is_booster_unlocked(booster_id: String, furthest_unlocked: int) -> bool:
	var f: int = maxi(1, furthest_unlocked)
	match booster_id:
		"pregame_hourglass":
			return f >= 10
		"ingame_magnet":
			return f >= 20
		"ingame_shield":
			return f >= 30
		"ingame_freeze":
			return f >= 40
		"special_gold":
			return f >= 50
		_:
			return true
