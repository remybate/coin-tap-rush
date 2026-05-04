extends Node2D

## Taps needed to reach the next level (level 1 = score 0 .. POINTS_PER_LEVEL-1).
const POINTS_PER_LEVEL: int = 12
## Active falling items in levels 1–3; level 4+ uses every node in _collectibles.
const COLLECTIBLES_BASE_COUNT: int = 10
## Lives (shown as hearts). Game over when this hits zero.
const MAX_LIVES: int = 5
const HEART_EMOJI: String = "❤️"
## Playfield: coins that fall below this Y (viewport pixels) count as missed — aligns with bottom HUD strip.
const BOTTOM_HUD_RESERVE_PX: float = 128.0
const PARK_POS: Vector2 = Vector2(-4000, -4000)
const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_BEST: String = "best_score"
## Every N good taps without a miss raises combo tier: x2 at 5, x3 at 10, …
const COMBO_STEP: int = 5
## Flat points added per tap for each level above 1 (before combo multiply).
const LEVEL_BONUS_PER_LEVEL: int = 2

var score: int = 0
var best_score: int = 0
## Consecutive gold / silver / diamond taps; resets on miss or bomb tap.
var combo_streak: int = 0
var lives: int = MAX_LIVES
var missed_coins: int = 0
var game_over: bool = false

var _collectibles: Array[Collectible] = []
var _last_slot_count: int = -1

@onready var score_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/ScoreLabel
@onready var best_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/BestLabel
@onready var combo_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/ComboLabel
@onready var lives_label: Label = $CanvasLayer/TopBar/Margin/Row/LivesLabel
@onready var level_label: Label = $CanvasLayer/TopBar/Margin/Row/LevelLabel
@onready var miss_summary_label: Label = $CanvasLayer/BottomBar/Margin/VBox/MissSummaryLabel
@onready var warning_label: Label = $CanvasLayer/BottomBar/Margin/VBox/WarningLabel
@onready var game_over_overlay: Control = $CanvasLayer/GameOverOverlay
@onready var final_score_label: Label = $CanvasLayer/GameOverOverlay/Center/VBox/FinalScoreLabel
@onready var game_over_best_label: Label = $CanvasLayer/GameOverOverlay/Center/VBox/BestScoreLabel
@onready var play_again_button: Button = $CanvasLayer/GameOverOverlay/Center/VBox/PlayAgainButton
@onready var home_button: Button = $CanvasLayer/GameOverOverlay/Center/VBox/HomeButton


func _ready() -> void:
	add_to_group("main")
	_load_best_score()
	play_again_button.pressed.connect(_on_play_again_pressed)
	home_button.pressed.connect(_on_home_pressed)
	for ch in get_children():
		if ch is Collectible:
			_collectibles.append(ch as Collectible)
	_collectibles.sort_custom(func(a: Collectible, b: Collectible) -> bool: return a.get_index() < b.get_index())
	_last_slot_count = -1
	_refresh_ui()


func get_danger_y() -> float:
	var h: float = max(get_viewport_rect().size.y, 600.0)
	return h - BOTTOM_HUD_RESERVE_PX


func is_game_over() -> bool:
	return game_over


func get_level() -> int:
	return score / POINTS_PER_LEVEL + 1


## Level 1: slow · 2: faster · 3+: faster still · 4+: same curve continues (more items via slots).
func get_fall_speed_range() -> Vector2:
	var lvl: int = get_level()
	if lvl <= 1:
		return Vector2(46, 74)
	if lvl == 2:
		return Vector2(88, 126)
	if lvl == 3:
		return Vector2(118, 165)
	if lvl == 4:
		return Vector2(142, 192)
	var t: int = lvl - 4
	return Vector2(142.0 + float(t) * 15.0, 192.0 + float(t) * 19.0)


## Red bombs appear from level 3 onward.
func bombs_enabled() -> bool:
	return get_level() >= 3


func _active_slot_count() -> int:
	if get_level() >= 4:
		return _collectibles.size()
	return min(COLLECTIBLES_BASE_COUNT, _collectibles.size())


func should_run_collectible(c: Collectible) -> bool:
	var idx: int = _collectibles.find(c)
	if idx < 0:
		return true
	return idx < _active_slot_count() and not game_over


func _sync_collectible_slots() -> void:
	if _collectibles.is_empty():
		return
	var n: int = 0 if game_over else _active_slot_count()
	if n == _last_slot_count:
		return
	var prev_n: int = _last_slot_count
	_last_slot_count = n
	for i in _collectibles.size():
		var c: Collectible = _collectibles[i]
		var on: bool = i < n
		if on:
			c.visible = true
			c.disabled = false
			c.set_process(true)
			var should_reset: bool = (prev_n < 0 and i < n) or (prev_n >= 0 and i >= prev_n and i < n)
			if should_reset:
				c.reset_for_new_game()
		else:
			c.visible = false
			c.set_process(false)
			c.disabled = true
			c.position = PARK_POS


func register_collectible(k: Collectible.Kind) -> void:
	if game_over:
		return
	if k == Collectible.Kind.BOMB:
		combo_streak = 0
		lives -= 1
		_refresh_ui()
		if lives <= 0:
			_trigger_game_over()
		return
	var base_pts: int = 0
	match k:
		Collectible.Kind.GOLD:
			base_pts = 1
		Collectible.Kind.SILVER_BIG:
			base_pts = 5
		Collectible.Kind.DIAMOND:
			base_pts = 10
		_:
			_refresh_ui()
			return
	var lvl_before: int = score / POINTS_PER_LEVEL + 1
	combo_streak += 1
	var combo_mult: int = 1 + combo_streak / COMBO_STEP
	var level_bonus: int = max(0, lvl_before - 1) * LEVEL_BONUS_PER_LEVEL
	score += base_pts * combo_mult + level_bonus
	_refresh_ui()


func register_miss() -> void:
	if game_over:
		return
	combo_streak = 0
	lives -= 1
	missed_coins += 1
	_refresh_ui()
	if lives <= 0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	combo_streak = 0
	if score > best_score:
		best_score = score
		_save_best_score()
	final_score_label.text = "Final Score: %d" % score
	if game_over_best_label:
		game_over_best_label.text = "Best Score: %d" % best_score
	game_over_overlay.visible = true
	for c in get_tree().get_nodes_in_group("coin"):
		c.set_process(false)
		c.disabled = true


func _on_play_again_pressed() -> void:
	game_over = false
	score = 0
	combo_streak = 0
	lives = MAX_LIVES
	missed_coins = 0
	game_over_overlay.visible = false
	_last_slot_count = -1
	_refresh_ui()


func _on_home_pressed() -> void:
	get_tree().reload_current_scene()


func _lives_text() -> String:
	var hearts := ""
	for _i in range(max(lives, 0)):
		hearts += HEART_EMOJI
	return "Lives: %d/%d %s" % [lives, MAX_LIVES, hearts]


func _level_help_text() -> String:
	var lvl: int = get_level()
	var combo_hint := " Every %d good taps in a row raises combo (x2, x3…). Misses reset combo." % COMBO_STEP
	var bonus_hint := " Level bonus: +%d pts per tap per level above 1." % LEVEL_BONUS_PER_LEVEL
	if lvl <= 1:
		return "Level 1: slow coins." + combo_hint + bonus_hint + " High score is saved on your device."
	if lvl == 2:
		return "Level 2: faster coins. No bombs yet." + combo_hint
	if lvl == 3:
		return "Level 3: bombs appear — tapping a bomb resets combo and costs a life." + bonus_hint
	return "Level 4+: more items at once." + combo_hint


func _load_best_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		best_score = 0
		return
	best_score = int(cfg.get_value(SAVE_SECTION, KEY_BEST, 0))


func _save_best_score() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value(SAVE_SECTION, KEY_BEST, best_score)
	cfg.save(SAVE_PATH)


func _refresh_ui() -> void:
	if score_label:
		score_label.text = "Score: %d" % score
	if best_label:
		best_label.text = "High: %d (saved)" % max(best_score, score)
	if combo_label:
		if combo_streak == 0:
			combo_label.text = "Combo x1 · %d taps without miss → x2" % COMBO_STEP
		else:
			var mult: int = 1 + combo_streak / COMBO_STEP
			var until_next: int = (1 + combo_streak / COMBO_STEP) * COMBO_STEP - combo_streak
			combo_label.text = "Combo x%d · streak %d (%d to x%d)" % [mult, combo_streak, until_next, mult + 1]
	if lives_label:
		lives_label.text = _lives_text()
	if level_label:
		level_label.text = "Level: %d" % get_level()
	if miss_summary_label:
		miss_summary_label.text = "Missed coins: %d" % missed_coins
	if warning_label:
		if game_over:
			warning_label.text = "Game over — Play Again or Home."
		elif lives <= 1:
			warning_label.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
			warning_label.text = "Danger: last life! Coin or gem in the strip costs a life. " + _level_help_text()
		elif lives <= 3:
			warning_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
			warning_label.text = "Low lives — " + _level_help_text()
		else:
			warning_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.8))
			warning_label.text = _level_help_text()
	if not game_over:
		_sync_collectible_slots()
