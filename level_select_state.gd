class_name LevelSelectState
extends RefCounted

## When > 0, `game.tscn` reads this once after loading save and applies the chosen level.
static var _pending_level: int = -1
## Pre-game popup: consume on run start in `game.gd` (charges deducted if stock allows).
static var _pregame_use_bomb_clear: bool = false
static var _pregame_use_start_slow: bool = false


static func request_start_at_level(level: int) -> void:
	_pending_level = clampi(level, 1, 999_999)


static func set_pregame_boosters(use_bomb_clear: bool, use_start_slow: bool) -> void:
	_pregame_use_bomb_clear = use_bomb_clear
	_pregame_use_start_slow = use_start_slow


static func consume_pending_level() -> int:
	var p: int = _pending_level
	_pending_level = -1
	return p


static func consume_pregame_flags() -> Dictionary:
	var d: Dictionary = {
		"bomb_clear": _pregame_use_bomb_clear,
		"start_slow": _pregame_use_start_slow,
	}
	_pregame_use_bomb_clear = false
	_pregame_use_start_slow = false
	return d


static func has_pending() -> bool:
	return _pending_level > 0
