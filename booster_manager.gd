extends Node

## Autoload: save key names and helpers for booster inventory (progress section).
## Pre-game (level map popup) uses bomb-clear + start-slow stocks.
## Retry (game over) uses legacy lightning + hourglass.
## In-game HUD uses freeze / slowmo / magnet / shield.

const SAVE_SECTION: String = "progress"

const KEY_BOMB_CLEAR: String = "booster_bomb_clear"
const KEY_START_SLOW: String = "booster_start_slow"
const KEY_INGAME_FREEZE: String = "ingame_freeze"
const KEY_INGAME_SLOWMO: String = "ingame_slowmo"
const KEY_INGAME_MAGNET: String = "ingame_magnet"
const KEY_SHIELD: String = "booster_shield"

## Retry screen (unchanged keys in save file).
const KEY_RETRY_LIGHTNING: String = "booster_lightning"
const KEY_RETRY_HOURGLASS: String = "booster_hourglass"


func roll_level_complete_bonus(rng: RandomNumberGenerator) -> Dictionary:
	## ~40% chance; pick one stock to grant +1.
	if rng.randf() > 0.4:
		return {}
	var pool: Array[String] = [
		KEY_INGAME_FREEZE,
		KEY_INGAME_SLOWMO,
		KEY_INGAME_MAGNET,
		KEY_SHIELD,
		KEY_BOMB_CLEAR,
		KEY_START_SLOW,
		KEY_RETRY_LIGHTNING,
		KEY_RETRY_HOURGLASS,
	]
	return {"key": pool[rng.randi_range(0, pool.size() - 1)], "amount": 1}
