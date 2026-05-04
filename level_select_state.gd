class_name LevelSelectState
extends RefCounted

## When > 0, `game.tscn` reads this once after loading save and applies the chosen level.
static var _pending_level: int = -1


static func request_start_at_level(level: int) -> void:
	_pending_level = clampi(level, 1, 999_999)


static func consume_pending_level() -> int:
	var p: int = _pending_level
	_pending_level = -1
	return p


static func has_pending() -> bool:
	return _pending_level > 0
