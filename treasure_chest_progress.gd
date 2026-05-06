extends RefCounted
class_name TreasureChestProgress

const PlayerProfileResolve = preload("res://player_profile_resolve.gd")

## Tracks streak toward a chest and queued chests; persists in the main progress ConfigFile.

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_STREAK: String = "treasure_chest_streak"
const KEY_PENDING: String = "treasure_chest_pending"
const KEY_SAVED_SCORE: String = "saved_score"
const KEY_FURTHEST_LEVEL: String = "furthest_level_unlocked"
const KEY_RETRY_LIGHTNING: String = "booster_lightning"
const KEY_RETRY_HOURGLASS: String = "booster_hourglass"

## Complete this many levels to earn one treasure chest.
const LEVELS_PER_CHEST: int = 3


static func read_streak_and_pending() -> Vector2i:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return Vector2i(0, 0)
	var streak: int = clampi(int(cfg.get_value(SAVE_SECTION, KEY_STREAK, 0)), 0, LEVELS_PER_CHEST - 1)
	var pending: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_PENDING, 0)))
	return Vector2i(streak, pending)


static func levels_until_next_chest() -> int:
	var v: Vector2i = read_streak_and_pending()
	if v.y > 0:
		return 0
	return maxi(1, LEVELS_PER_CHEST - v.x)


static func record_level_cleared() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var streak: int = clampi(int(cfg.get_value(SAVE_SECTION, KEY_STREAK, 0)), 0, LEVELS_PER_CHEST - 1)
	var pending: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_PENDING, 0)))
	streak += 1
	if streak >= LEVELS_PER_CHEST:
		pending += 1
		streak = 0
	cfg.set_value(SAVE_SECTION, KEY_STREAK, streak)
	cfg.set_value(SAVE_SECTION, KEY_PENDING, pending)
	cfg.save(SAVE_PATH)


static func _booster_label(key: String, amount: int) -> String:
	match key:
		BoosterManager.KEY_INGAME_FREEZE:
			return "+%d Freeze charm(s)" % amount
		BoosterManager.KEY_INGAME_SLOWMO:
			return "+%d Slow-motion charm(s)" % amount
		BoosterManager.KEY_INGAME_MAGNET:
			return "+%d Magnet charm(s)" % amount
		BoosterManager.KEY_SHIELD:
			return "+%d Shield plate(s)" % amount
		BoosterManager.KEY_BOMB_CLEAR:
			return "+%d Spark Sweep charm(s)" % amount
		BoosterManager.KEY_START_SLOW:
			return "+%d Hourglass river charm(s)" % amount
		KEY_RETRY_LIGHTNING:
			return "+%d Retry lightning charge(s)" % amount
		KEY_RETRY_HOURGLASS:
			return "+%d Retry hourglass charge(s)" % amount
		_:
			return "+%d Bonus charm(s)" % amount


static func _add_booster(cfg: ConfigFile, key: String, amount: int) -> void:
	var cur: int = clampi(int(cfg.get_value(SAVE_SECTION, key, 0)), 0, 99)
	cfg.set_value(SAVE_SECTION, key, clampi(cur + amount, 0, 99))


## Rolls loot, applies to save, decrements pending. Returns empty dict if nothing to open.
static func try_open_one_chest(rng: RandomNumberGenerator) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	var pending: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_PENDING, 0)))
	if pending < 1:
		return {}
	pending -= 1
	cfg.set_value(SAVE_SECTION, KEY_PENDING, pending)

	var furthest: int = maxi(1, int(cfg.get_value(SAVE_SECTION, KEY_FURTHEST_LEVEL, 1)))
	var coins: int = 36 + furthest * 2 + rng.randi_range(0, 52)
	coins = clampi(coins, 28, 360)
	var vault: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_SAVED_SCORE, 0)))
	cfg.set_value(SAVE_SECTION, KEY_SAVED_SCORE, vault + coins)

	var primary_pool: Array = [
		BoosterManager.KEY_INGAME_MAGNET,
		BoosterManager.KEY_INGAME_FREEZE,
		BoosterManager.KEY_SHIELD,
		BoosterManager.KEY_BOMB_CLEAR,
		BoosterManager.KEY_START_SLOW,
	]
	var b1: String = str(primary_pool[rng.randi_range(0, primary_pool.size() - 1)])
	_add_booster(cfg, b1, 1)

	var lines: PackedStringArray = PackedStringArray()
	lines.append("+%d vault coins" % coins)
	lines.append(_booster_label(b1, 1))

	if rng.randf() < 0.48:
		var extra_pool: Array = [
			BoosterManager.KEY_INGAME_SLOWMO,
			KEY_RETRY_LIGHTNING,
			KEY_RETRY_HOURGLASS,
		]
		var b2: String = str(extra_pool[rng.randi_range(0, extra_pool.size() - 1)])
		_add_booster(cfg, b2, 1)
		lines.append(_booster_label(b2, 1))

	var pp: Node = PlayerProfileResolve.node()
	if pp != null:
		pp.grant_xp_for_treasure_chest(cfg)
	cfg.save(SAVE_PATH)
	return {"ok": true, "coins": coins, "lines": lines}
