extends Node

## Local daily missions: progress + claims in `daily_missions` save section; resets when local calendar day changes.

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SECTION: String = "daily_missions"
const PROGRESS_SECTION: String = "progress"

const KEY_DAY: String = "day_key"
const KEY_M0: String = "m0_collect"
const KEY_M0C: String = "m0_claimed"
const KEY_M1: String = "m1_levels"
const KEY_M1C: String = "m1_claimed"
const KEY_M2: String = "m2_combo5"
const KEY_M2C: String = "m2_claimed"

const KEY_SAVED_SCORE: String = "saved_score"

const GOAL_COINS: int = 100
const GOAL_LEVELS: int = 3
const COMBO_MULT_GOAL: int = 5


func _ready() -> void:
	print("[DailyMissions] _ready")
	ensure_current_day()


func day_key_today() -> int:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return int(t.year) * 10000 + int(t.month) * 100 + int(t.day)


func ensure_current_day() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(SAVE_PATH)
	var today: int = day_key_today()
	var stored: int = int(cfg.get_value(SECTION, KEY_DAY, 0)) if err == OK else 0
	if stored != today:
		cfg.set_value(SECTION, KEY_DAY, today)
		cfg.set_value(SECTION, KEY_M0, 0)
		cfg.set_value(SECTION, KEY_M0C, false)
		cfg.set_value(SECTION, KEY_M1, 0)
		cfg.set_value(SECTION, KEY_M1C, false)
		cfg.set_value(SECTION, KEY_M2, false)
		cfg.set_value(SECTION, KEY_M2C, false)
		cfg.save(SAVE_PATH)


func add_coin_collects(amount: int) -> void:
	if amount <= 0:
		return
	ensure_current_day()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if bool(cfg.get_value(SECTION, KEY_M0C, false)):
		return
	var p: int = mini(GOAL_COINS, int(cfg.get_value(SECTION, KEY_M0, 0)) + amount)
	cfg.set_value(SECTION, KEY_M0, p)
	cfg.save(SAVE_PATH)


func record_level_cleared() -> void:
	ensure_current_day()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if bool(cfg.get_value(SECTION, KEY_M1C, false)):
		return
	var p: int = mini(GOAL_LEVELS, int(cfg.get_value(SECTION, KEY_M1, 0)) + 1)
	cfg.set_value(SECTION, KEY_M1, p)
	cfg.save(SAVE_PATH)


func mark_combo_multiplier_at_least(mult: int) -> void:
	if mult < COMBO_MULT_GOAL:
		return
	ensure_current_day()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if bool(cfg.get_value(SECTION, KEY_M2C, false)):
		return
	cfg.set_value(SECTION, KEY_M2, true)
	cfg.save(SAVE_PATH)


func has_claimable_reward() -> bool:
	ensure_current_day()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	var m0: int = int(cfg.get_value(SECTION, KEY_M0, 0))
	var m0c: bool = bool(cfg.get_value(SECTION, KEY_M0C, false))
	if m0 >= GOAL_COINS and not m0c:
		return true
	var m1: int = int(cfg.get_value(SECTION, KEY_M1, 0))
	var m1c: bool = bool(cfg.get_value(SECTION, KEY_M1C, false))
	if m1 >= GOAL_LEVELS and not m1c:
		return true
	var m2: bool = bool(cfg.get_value(SECTION, KEY_M2, false))
	var m2c: bool = bool(cfg.get_value(SECTION, KEY_M2C, false))
	if m2 and not m2c:
		return true
	return false


func get_rows_for_ui() -> Array[Dictionary]:
	ensure_current_day()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var m0: int = int(cfg.get_value(SECTION, KEY_M0, 0))
	var m0c: bool = bool(cfg.get_value(SECTION, KEY_M0C, false))
	var m1: int = int(cfg.get_value(SECTION, KEY_M1, 0))
	var m1c: bool = bool(cfg.get_value(SECTION, KEY_M1C, false))
	var m2: bool = bool(cfg.get_value(SECTION, KEY_M2, false))
	var m2c: bool = bool(cfg.get_value(SECTION, KEY_M2C, false))
	var rows: Array[Dictionary] = [
		{
			"id": 0,
			"title": "Coin rush",
			"desc": "Collect %d gleams (coins & gems) today." % GOAL_COINS,
			"current": m0,
			"goal": GOAL_COINS,
			"claimed": m0c,
			"reward": "+150 vault coins",
		},
		{
			"id": 1,
			"title": "Marathon",
			"desc": "Clear %d levels today (any difficulty)." % GOAL_LEVELS,
			"current": m1,
			"goal": GOAL_LEVELS,
			"claimed": m1c,
			"reward": "+2 Magnet charms",
		},
		{
			"id": 2,
			"title": "Combo master",
			"desc": "Reach combo ×%d in a single run (streak 20+ gleams)." % COMBO_MULT_GOAL,
			"current": 1 if m2 else 0,
			"goal": 1,
			"claimed": m2c,
			"reward": "+100 coins & +1 Slow",
		},
	]
	return rows


func claim_mission(mission_id: int) -> Dictionary:
	ensure_current_day()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	match mission_id:
		0:
			var m0: int = int(cfg.get_value(SECTION, KEY_M0, 0))
			if m0 < GOAL_COINS:
				return {"ok": false, "msg": "Keep collecting gleams!"}
			if bool(cfg.get_value(SECTION, KEY_M0C, false)):
				return {"ok": false, "msg": "Reward already claimed."}
			cfg.set_value(SECTION, KEY_M0C, true)
			_grant_vault(cfg, 150)
			cfg.save(SAVE_PATH)
			return {"ok": true, "msg": "+150 coins added to your vault."}
		1:
			var m1: int = int(cfg.get_value(SECTION, KEY_M1, 0))
			if m1 < GOAL_LEVELS:
				return {"ok": false, "msg": "Finish more levels first!"}
			if bool(cfg.get_value(SECTION, KEY_M1C, false)):
				return {"ok": false, "msg": "Reward already claimed."}
			cfg.set_value(SECTION, KEY_M1C, true)
			_grant_booster(cfg, BoosterManager.KEY_INGAME_MAGNET, 2)
			cfg.save(SAVE_PATH)
			return {"ok": true, "msg": "+2 Magnet charms in your HUD stock."}
		2:
			if not bool(cfg.get_value(SECTION, KEY_M2, false)):
				return {"ok": false, "msg": "Hit combo ×%d in a run today." % COMBO_MULT_GOAL}
			if bool(cfg.get_value(SECTION, KEY_M2C, false)):
				return {"ok": false, "msg": "Reward already claimed."}
			cfg.set_value(SECTION, KEY_M2C, true)
			_grant_vault(cfg, 100)
			_grant_booster(cfg, BoosterManager.KEY_INGAME_SLOWMO, 1)
			cfg.save(SAVE_PATH)
			return {"ok": true, "msg": "+100 vault coins and +1 Slow-motion charm."}
		_:
			return {"ok": false, "msg": "Unknown mission."}


func _grant_vault(cfg: ConfigFile, coins: int) -> void:
	if coins <= 0:
		return
	var v: int = maxi(0, int(cfg.get_value(PROGRESS_SECTION, KEY_SAVED_SCORE, 0)))
	cfg.set_value(PROGRESS_SECTION, KEY_SAVED_SCORE, v + coins)


func _grant_booster(cfg: ConfigFile, key: String, qty: int) -> void:
	if qty <= 0 or key.is_empty():
		return
	var b: int = int(cfg.get_value(PROGRESS_SECTION, key, 0))
	cfg.set_value(PROGRESS_SECTION, key, clampi(b + qty, 0, 99))
