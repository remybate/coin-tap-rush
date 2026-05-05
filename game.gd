extends Node2D

const MAIN_MENU_SCENE: String = "res://main_menu.tscn"
const LEVEL_MAP_SCENE: String = "res://level_map.tscn"

## Legacy cap for per-tap level bonus (keeps combo math bounded at extreme levels).
const COLLECTIBLES_CAP_SLOTS: int = 20
## Lives (shown as hearts). Game over when this hits zero.
const MAX_LIVES: int = 5
const HEART_EMOJI: String = "❤️"
## Playfield: coins that fall below this Y (viewport pixels) count as missed — aligns with bottom HUD strip.
const BOTTOM_HUD_RESERVE_PX: float = 248.0
const PARK_POS: Vector2 = Vector2(-4000, -4000)
const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_BEST: String = "best_score"
const KEY_SAVED_SCORE: String = "saved_score"
## Run score toward level goals (separate from coin vault).
const KEY_SESSION_SCORE: String = "session_score"
const KEY_PROGRESSION: String = "saved_progression_level"
const KEY_FURTHEST_LEVEL: String = "furthest_level_unlocked"
const KEY_CURRENT_LEVEL: String = "current_level_playing"
const KEY_LEVEL_SCORE_FLOOR: String = "level_score_floor"
const KEY_BOOST_LIGHTNING: String = "booster_lightning"
const KEY_BOOST_HOURGLASS: String = "booster_hourglass"
const KEY_BOOST_SHIELD: String = "booster_shield"
const KEY_RETRY_CHARGES: String = "retry_charges"
const KEY_RETRY_BLOCK_UNTIL: String = "retry_block_until_unix"
## Lifetime stats for trophies (do not affect scoring).
const KEY_STAT_GLEAMS: String = "stat_gleams_collected"
const KEY_STAT_BOMBS_DODGED: String = "stat_bombs_dodged"
const KEY_STAT_MAX_COMBO: String = "stat_max_combo_streak"
## Retries after Level Failed before a long cooldown (each Retry tap uses one).
const MAX_RETRY_CHARGES: int = 5
const RETRY_COOLDOWN_SEC: int = 3 * 3600
## Every N good taps without a miss raises combo tier: x2 at 5, x3 at 10, …
const COMBO_STEP: int = 5
var score: int = 0
var best_score: int = 0
## Bank coins (persisted in saved_score). Only grows after a level completes (fly animation).
var vault_coins: int = 0
## Coins earned this level from collecting gleams (not banked until level completes).
var level_coins_collected: int = 0
var _cached_level_bonus: Dictionary = {}
var _level_payout_ready: bool = false
## Consecutive gold / silver / diamond taps; resets on miss or bomb tap.
var combo_streak: int = 0
var lives: int = MAX_LIVES
var missed_coins: int = 0
var game_over: bool = false
## Level currently being played (may replay earlier maps).
var progression_level: int = 1
## Highest level unlocked on the map (never shrinks).
var furthest_level_unlocked: int = 1
## Session score at the moment this level’s goals started (points gained = score - floor).
var _level_score_at_start: int = 0
## Remaining seconds for optional time limit; <= 0 means off.
var _level_time_remaining: float = -1.0
## Cached output of LevelProgression.get_level_config(progression_level).
var _cached_cfg: Dictionary = {}
## Inventory for the level-fail screen (persisted).
var booster_lightning: int = 5
var booster_hourglass: int = 4
## Absorbs one bomb tap (no life lost); consumed on use.
var booster_shield: int = 2
## Pre-level map charms (separate from retry ⚡/⏳ stocks).
var booster_bomb_clear: int = 3
var booster_start_slow: int = 3
## In-game HUD consumables.
var ingame_freeze: int = 2
var ingame_slowmo: int = 2
var ingame_magnet: int = 2
## After Retry with ⚡ booster: slower new spawns for this many seconds.
var _booster_slow_timer: float = 0.0
var _ingame_slow_timer: float = 0.0
var _freeze_timer: float = 0.0
var _magnet_timer: float = 0.0
var _run_bomb_clear_pending: bool = false
var _magnet_target_x: float = -1.0
var _booster_feedback_timer: float = 0.0
var _booster_feedback_text: String = ""
var _reward_rng := RandomNumberGenerator.new()
## Absorbs the next bomb tap or missed-coin penalty (from tapping the Shield HUD charm).
var _shield_blocks_next: int = 0
## Can become 6 when Retry uses ⏳ booster.
var _effective_max_lives: int = MAX_LIVES
## Retries left after game over (max 5). At 0, Retry is locked until RETRY_COOLDOWN_SEC passes.
var retry_charges: int = MAX_RETRY_CHARGES
## Unix time when retry charges refill to max; 0 = not waiting.
var retry_block_until_unix: int = 0
## Good taps (coins/gems) — used for trophy progress.
var stat_gleams_collected: int = 0
## Bombs that left the screen without being tapped.
var stat_bombs_dodged: int = 0
## Best consecutive good-tap streak this save has seen.
var stat_max_combo_streak: int = 0

var _collectibles: Array[Collectible] = []
var _last_slot_count: int = -1
## When true, gameplay was paused only because Settings was opened from the HUD (not Pause / level-up).
var _paused_for_hud_settings: bool = false

@onready var score_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/ScoreLabel
@onready var best_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/BestLabel
@onready var combo_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/ComboLabel
@onready var vault_coins_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/VaultCoinsLabel
@onready var level_coins_hud_label: Label = $CanvasLayer/TopBar/Margin/Row/ScoreColumn/LevelCoinsHudLabel
@onready var lives_label: Label = $CanvasLayer/TopBar/Margin/Row/LivesLabel
@onready var level_label: Label = $CanvasLayer/TopBar/Margin/Row/LevelLabel
@onready var controls_label: Label = $CanvasLayer/BottomBar/Margin/VBox/ControlsLabel
@onready var miss_summary_label: Label = $CanvasLayer/BottomBar/Margin/VBox/MissSummaryLabel
@onready var warning_label: Label = $CanvasLayer/BottomBar/Margin/VBox/WarningLabel
@onready var booster_freeze_btn: Button = $CanvasLayer/BottomBar/Margin/VBox/BoosterBar/BoosterFreeze
@onready var booster_slow_btn: Button = $CanvasLayer/BottomBar/Margin/VBox/BoosterBar/BoosterSlow
@onready var booster_magnet_btn: Button = $CanvasLayer/BottomBar/Margin/VBox/BoosterBar/BoosterMagnet
@onready var booster_shield_btn: Button = $CanvasLayer/BottomBar/Margin/VBox/BoosterBar/BoosterShield
@onready var game_over_screen: CanvasItem = $CanvasLayer/GameOverScreen
@onready var settings_screen: SettingsScreen = $CanvasLayer/SettingsScreen
@onready var pause_screen: PauseScreen = $CanvasLayer/PauseScreen
@onready var how_to_play_screen: HowToPlayScreen = $CanvasLayer/HowToPlayScreen
@onready var pause_button: Button = $CanvasLayer/TopBar/Margin/Row/PauseButton
@onready var settings_button: Button = $CanvasLayer/TopBar/Margin/Row/SettingsButton
@onready var level_complete_screen: Control = $CanvasLayer/LevelCompleteScreen
@onready var _collect_burst: CPUParticles2D = $CollectBurst


func _ready() -> void:
	add_to_group("main")
	get_tree().paused = false
	_reward_rng.randomize()
	_load_progress_from_disk()
	var pending_map: int = LevelSelectState.consume_pending_level()
	if pending_map > 0:
		_apply_level_from_map_selection(pending_map)
	else:
		_begin_level_segment(false)
	_apply_pregame_charm_selection(LevelSelectState.consume_pregame_flags())
	pause_button.pressed.connect(_on_pause_button_pressed)
	settings_button.pressed.connect(_on_settings_open)
	level_complete_screen.continue_pressed.connect(_on_level_continue_pressed)
	level_complete_screen.home_pressed.connect(_on_level_complete_home_pressed)
	game_over_screen.play_again_pressed.connect(_on_play_again_pressed)
	game_over_screen.home_pressed.connect(_on_home_pressed)
	pause_screen.resume_pressed.connect(_on_pause_resume_pressed)
	pause_screen.settings_pressed.connect(_on_pause_settings_pressed)
	pause_screen.how_to_play_pressed.connect(_on_pause_how_to_play_pressed)
	pause_screen.main_menu_pressed.connect(_on_pause_main_menu_pressed)
	if settings_screen != null:
		settings_screen.progress_reset.connect(_on_progress_reset)
		settings_screen.closed.connect(_on_settings_closed)
	if booster_freeze_btn != null:
		booster_freeze_btn.pressed.connect(_on_booster_freeze_pressed)
	if booster_slow_btn != null:
		booster_slow_btn.pressed.connect(_on_booster_slow_pressed)
	if booster_magnet_btn != null:
		booster_magnet_btn.pressed.connect(_on_booster_magnet_pressed)
	if booster_shield_btn != null:
		booster_shield_btn.pressed.connect(_on_booster_shield_hud_pressed)
	for ch in get_children():
		if ch is Collectible:
			_collectibles.append(ch as Collectible)
	_collectibles.sort_custom(func(a: Collectible, b: Collectible) -> bool: return a.get_index() < b.get_index())
	_last_slot_count = -1
	set_process(true)
	_refresh_ui()


func _on_progress_reset() -> void:
	_load_progress_from_disk()
	_refresh_ui()


func get_danger_y() -> float:
	var h: float = max(get_viewport_rect().size.y, 600.0)
	return h - BOTTOM_HUD_RESERVE_PX


func is_game_over() -> bool:
	return game_over


func get_level() -> int:
	return progression_level


func _begin_level_segment(update_floor_from_score: bool) -> void:
	_cached_cfg = LevelProgression.get_level_config(progression_level)
	if update_floor_from_score:
		_level_score_at_start = score
	var tl: float = float(_cached_cfg.get("time_limit", 0.0))
	_level_time_remaining = tl if tl > 0.05 else -1.0
	_last_slot_count = -1


func _level_targets_met() -> bool:
	if _cached_cfg.is_empty():
		return false
	var delta_pts: int = score - _level_score_at_start
	if delta_pts >= int(_cached_cfg.get("target_score", 999999)):
		return true
	if level_coins_collected >= int(_cached_cfg.get("target_coins", 999999)):
		return true
	return false


func _process(delta: float) -> void:
	if _booster_slow_timer > 0.0:
		_booster_slow_timer = maxf(0.0, _booster_slow_timer - delta)
	if _ingame_slow_timer > 0.0:
		_ingame_slow_timer = maxf(0.0, _ingame_slow_timer - delta)
	if _freeze_timer > 0.0:
		_freeze_timer = maxf(0.0, _freeze_timer - delta)
	if _magnet_timer > 0.0:
		_magnet_timer = maxf(0.0, _magnet_timer - delta)
	if _booster_feedback_timer > 0.0:
		_booster_feedback_timer = maxf(0.0, _booster_feedback_timer - delta)
	if _level_time_remaining > 0.0 and not game_over and not level_complete_screen.visible:
		_level_time_remaining = maxf(0.0, _level_time_remaining - delta)
		if _level_time_remaining <= 0.0:
			_trigger_game_over()
	_update_retry_refill_if_needed()
	_try_apply_pending_bomb_clear()
	if game_over and game_over_screen.visible:
		game_over_screen.refresh_retry_ui(retry_charges, _retry_wait_seconds())


## Scales fall speed from collectibles when slow charms are active (spawn jitter + live motion).
func get_fall_speed_bonus_scale() -> float:
	var s: float = 1.0
	if _booster_slow_timer > 0.0:
		s *= 0.62
	if _ingame_slow_timer > 0.0:
		s *= 0.55
	return s


func get_collectible_vertical_mult() -> float:
	if _freeze_timer > 0.0:
		return 0.0
	return get_fall_speed_bonus_scale()


func set_magnet_focus(world_x: float) -> void:
	_magnet_target_x = world_x


func apply_magnet_to_collectible(c: Collectible, delta: float) -> void:
	if _magnet_timer <= 0.0 or c.kind == Collectible.Kind.BOMB:
		return
	var tx: float = _magnet_target_x
	if tx < 0.0:
		tx = maxf(get_viewport_rect().size.x * 0.5, 120.0)
	var t: float = clampf(5.5 * delta, 0.0, 1.0)
	c.base_x = lerpf(c.base_x, tx, t)


func _try_apply_pending_bomb_clear() -> void:
	if not _run_bomb_clear_pending or game_over:
		return
	if not bombs_enabled():
		booster_bomb_clear += 1
		_run_bomb_clear_pending = false
		_save_progress_file()
		return
	var any_bomb_visible: bool = false
	for c in _collectibles:
		if is_instance_valid(c) and c.visible and c.kind == Collectible.Kind.BOMB:
			any_bomb_visible = true
			break
	if not any_bomb_visible:
		return
	for c in _collectibles:
		if is_instance_valid(c) and c.visible and c.kind == Collectible.Kind.BOMB:
			c.convert_bomb_to_safe_coin()
	_flash_booster("Spark Sweep — bombs zapped!")
	_run_bomb_clear_pending = false


func _apply_pregame_charm_selection(pre: Dictionary) -> void:
	var want_bc: bool = bool(pre.get("bomb_clear", false))
	var want_ss: bool = bool(pre.get("start_slow", false))
	if want_bc and booster_bomb_clear > 0:
		booster_bomb_clear -= 1
		_run_bomb_clear_pending = true
	if want_ss and booster_start_slow > 0:
		booster_start_slow -= 1
		_booster_slow_timer = maxf(_booster_slow_timer, 10.0)
	_save_progress_file()


func _flash_booster(msg: String) -> void:
	_booster_feedback_text = msg
	_booster_feedback_timer = 2.0
	_refresh_ui()


func _update_retry_refill_if_needed() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	if retry_charges <= 0 and retry_block_until_unix > 0 and now >= retry_block_until_unix:
		retry_charges = MAX_RETRY_CHARGES
		retry_block_until_unix = 0
		_save_progress_file()


func _retry_wait_seconds() -> int:
	var now: int = int(Time.get_unix_time_from_system())
	if retry_charges > 0:
		return 0
	if retry_block_until_unix <= 0 or now >= retry_block_until_unix:
		return 0
	return retry_block_until_unix - now


func can_use_retry() -> bool:
	_update_retry_refill_if_needed()
	return retry_charges > 0


## Narrow band around config fall_speed so each spawn still feels unique.
func get_fall_speed_range() -> Vector2:
	var c: float = float(_cached_cfg.get("fall_speed", 200.0))
	c = maxf(c, 80.0)
	return Vector2(c * 0.88, c * 1.12)


func bombs_enabled() -> bool:
	return float(_cached_cfg.get("bomb_chance", 0.0)) > 0.0001


func _active_slot_count() -> int:
	var cap: int = _collectibles.size()
	var want: int = int(_cached_cfg.get("max_objects", 6))
	want = clampi(want, 1, COLLECTIBLES_CAP_SLOTS)
	return mini(cap, want)


func get_spawn_depth_range() -> Vector2:
	var si: float = float(_cached_cfg.get("spawn_interval", 1.0))
	var t: float = clampf((si - 0.35) / (1.5 - 0.35), 0.0, 1.0)
	var y_top: float = lerpf(-220.0, -95.0, t)
	var y_bot: float = lerpf(-55.0, -18.0, t)
	return Vector2(y_top, y_bot)


func get_collectible_kind_for_spawn(rng: RandomNumberGenerator) -> Collectible.Kind:
	if _cached_cfg.is_empty():
		return Collectible.Kind.GOLD
	var p_b: float = float(_cached_cfg.get("bomb_chance", 0.0))
	if bombs_enabled() and rng.randf() < p_b:
		return Collectible.Kind.BOMB
	var p_d: float = float(_cached_cfg.get("diamond_chance", 0.0))
	if p_d > 0.0001 and rng.randf() < p_d:
		return Collectible.Kind.DIAMOND
	var p_s: float = clampf(float(_cached_cfg.get("silver_chance", 0.32)), 0.12, 0.55)
	var g_bias: float = maxf(float(_cached_cfg.get("gold_bias", 1.0)), 0.25)
	var p_g: float = (1.0 - p_s) * g_bias
	var tot: float = p_g + p_s
	p_g /= tot
	p_s /= tot
	if rng.randf() < p_g:
		return Collectible.Kind.GOLD
	return Collectible.Kind.SILVER_BIG


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


func play_collect_burst(world_pos: Vector2, k: Collectible.Kind) -> void:
	if game_over or _collect_burst == null:
		return
	var tint := Color(1, 0.9, 0.38)
	match k:
		Collectible.Kind.SILVER_BIG:
			tint = Color(0.92, 0.96, 1.0)
		Collectible.Kind.DIAMOND:
			tint = Color(0.45, 0.92, 1.0)
		_:
			pass
	_collect_burst.burst_at(world_pos, tint)


func register_collectible(k: Collectible.Kind) -> void:
	if game_over:
		return
	if k == Collectible.Kind.BOMB:
		combo_streak = 0
		if _shield_blocks_next > 0:
			_shield_blocks_next -= 1
			_flash_booster("Aegis — blast absorbed!")
			_refresh_ui()
			_save_progress_file()
			return
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
	combo_streak += 1
	stat_gleams_collected += 1
	stat_max_combo_streak = maxi(stat_max_combo_streak, combo_streak)
	var combo_mult: int = 1 + combo_streak / COMBO_STEP
	var level_bonus: int = mini(maxi(0, progression_level - 1) * 2, 50)
	var pts: int = base_pts * combo_mult + level_bonus
	score += pts
	level_coins_collected += base_pts
	_refresh_ui()
	_save_progress_file()


func register_bomb_dodged() -> void:
	if game_over:
		return
	stat_bombs_dodged += 1
	_save_progress_file()


func register_miss() -> void:
	if game_over:
		return
	if _shield_blocks_next > 0:
		_shield_blocks_next -= 1
		combo_streak = 0
		AudioService.play_coin_tap()
		_flash_booster("Aegis — missed drop absorbed!")
		_refresh_ui()
		_save_progress_file()
		return
	AudioService.play_miss()
	combo_streak = 0
	lives -= 1
	missed_coins += 1
	_refresh_ui()
	if lives <= 0:
		_trigger_game_over()


func _clear_pause_state() -> void:
	get_tree().paused = false
	pause_screen.hide_pause()
	how_to_play_screen.hide_help()
	level_complete_screen.hide_screen()


func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	combo_streak = 0
	_clear_pause_state()
	AudioService.play_game_over()
	if score > best_score:
		best_score = score
	_save_progress_file()
	_update_retry_refill_if_needed()
	game_over_screen.show_results(score, best_score, booster_lightning, booster_hourglass, retry_charges, _retry_wait_seconds(), level_coins_collected)
	level_coins_collected = 0
	for c in get_tree().get_nodes_in_group("coin"):
		c.set_process(false)
		c.disabled = true


func _on_play_again_pressed(booster_id: int = -1) -> void:
	if not can_use_retry():
		AudioService.play_button_click()
		return
	AudioService.play_button_click()
	retry_charges -= 1
	if retry_charges <= 0:
		retry_block_until_unix = int(Time.get_unix_time_from_system()) + RETRY_COOLDOWN_SEC
	game_over = false
	combo_streak = 0
	missed_coins = 0
	_effective_max_lives = MAX_LIVES
	_booster_slow_timer = 0.0
	_ingame_slow_timer = 0.0
	_freeze_timer = 0.0
	_magnet_timer = 0.0
	_run_bomb_clear_pending = false
	_shield_blocks_next = 0
	level_coins_collected = 0
	lives = MAX_LIVES
	match booster_id:
		0:
			if booster_lightning > 0:
				booster_lightning -= 1
				_booster_slow_timer = 14.0
		1:
			if booster_hourglass > 0:
				booster_hourglass -= 1
				_effective_max_lives = MAX_LIVES + 1
				lives = MAX_LIVES + 1
		_:
			pass
	_clear_pause_state()
	game_over_screen.hide_screen()
	_last_slot_count = -1
	_refresh_ui()
	_save_progress_file()


func _on_home_pressed() -> void:
	AudioService.play_button_click()
	_save_progress_file()
	_clear_pause_state()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_settings_open() -> void:
	if level_complete_screen.visible:
		return
	if game_over:
		return
	AudioService.play_button_click()
	if not get_tree().paused:
		get_tree().paused = true
		_paused_for_hud_settings = true
	settings_screen.open_settings()


func _on_settings_closed() -> void:
	if _paused_for_hud_settings:
		get_tree().paused = false
		_paused_for_hud_settings = false


func _on_level_continue_pressed() -> void:
	if not _level_payout_ready:
		return
	AudioService.play_button_click()
	_level_payout_ready = false
	progression_level += 1
	furthest_level_unlocked = maxi(furthest_level_unlocked, progression_level)
	level_complete_screen.hide_screen()
	get_tree().paused = false
	_last_slot_count = -1
	_begin_level_segment(true)
	_refresh_ui()
	_save_progress_file()
	call_deferred("_try_offer_level_gate")


func _on_level_complete_home_pressed() -> void:
	if not _level_payout_ready:
		return
	AudioService.play_button_click()
	_level_payout_ready = false
	progression_level += 1
	furthest_level_unlocked = maxi(furthest_level_unlocked, progression_level)
	level_complete_screen.hide_screen()
	get_tree().paused = false
	_begin_level_segment(true)
	_save_progress_file()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _format_level_bonus_for_ui(d: Dictionary) -> String:
	if d.is_empty():
		return "No extra charm roll this time — your vault still sparkles."
	var k: String = str(d.get("key", ""))
	var amt: int = int(d.get("amount", 1))
	match k:
		BoosterManager.KEY_INGAME_FREEZE:
			return "+%d Freeze charm(s) added!" % amt
		BoosterManager.KEY_INGAME_SLOWMO:
			return "+%d Slow-motion charm(s) added!" % amt
		BoosterManager.KEY_INGAME_MAGNET:
			return "+%d Magnet charm(s) added!" % amt
		BoosterManager.KEY_SHIELD:
			return "+%d Shield plate(s) added!" % amt
		BoosterManager.KEY_BOMB_CLEAR:
			return "+%d Spark Sweep charm(s) added!" % amt
		BoosterManager.KEY_START_SLOW:
			return "+%d Hourglass river charm(s) added!" % amt
		BoosterManager.KEY_RETRY_LIGHTNING:
			return "+%d Retry lightning charge(s) added!" % amt
		BoosterManager.KEY_RETRY_HOURGLASS:
			return "+%d Retry hourglass charge(s) added!" % amt
		_:
			return "Mystery charm secured!"


func _apply_level_bonus_dictionary(d: Dictionary) -> void:
	if d.is_empty():
		return
	var k: String = str(d.get("key", ""))
	var amt: int = clampi(int(d.get("amount", 1)), 1, 9)
	match k:
		BoosterManager.KEY_INGAME_FREEZE:
			ingame_freeze = clampi(ingame_freeze + amt, 0, 99)
		BoosterManager.KEY_INGAME_SLOWMO:
			ingame_slowmo = clampi(ingame_slowmo + amt, 0, 99)
		BoosterManager.KEY_INGAME_MAGNET:
			ingame_magnet = clampi(ingame_magnet + amt, 0, 99)
		BoosterManager.KEY_SHIELD:
			booster_shield = clampi(booster_shield + amt, 0, 99)
		BoosterManager.KEY_BOMB_CLEAR:
			booster_bomb_clear = clampi(booster_bomb_clear + amt, 0, 99)
		BoosterManager.KEY_START_SLOW:
			booster_start_slow = clampi(booster_start_slow + amt, 0, 99)
		BoosterManager.KEY_RETRY_LIGHTNING:
			booster_lightning = clampi(booster_lightning + amt, 0, 99)
		BoosterManager.KEY_RETRY_HOURGLASS:
			booster_hourglass = clampi(booster_hourglass + amt, 0, 99)
		_:
			pass


func _commit_level_complete_payout() -> void:
	var earned: int = level_coins_collected
	vault_coins += earned
	level_coins_collected = 0
	_apply_level_bonus_dictionary(_cached_level_bonus)
	_cached_level_bonus = {}
	_save_progress_file()


func _begin_level_complete_fly() -> void:
	if not is_instance_valid(level_complete_screen) or not level_complete_screen.visible:
		return
	if vault_coins_label == null:
		_on_level_complete_fly_finished()
		return
	var target: Vector2 = vault_coins_label.get_global_rect().get_center()
	level_complete_screen.play_coin_fly(level_coins_collected, target, Callable(self, "_on_level_complete_fly_finished"))


func _on_level_complete_fly_finished() -> void:
	_commit_level_complete_payout()
	_level_payout_ready = true
	level_complete_screen.set_continue_enabled(true)
	_refresh_ui()


func _try_offer_level_gate() -> void:
	if game_over:
		return
	if level_complete_screen.visible:
		return
	if not _level_targets_met():
		return
	AudioService.play_level_up()
	_cached_level_bonus = BoosterManager.roll_level_complete_bonus(_reward_rng)
	var rewards_txt: String = _format_level_bonus_for_ui(_cached_level_bonus)
	level_complete_screen.show_for(progression_level, score, progression_level + 1, level_coins_collected, rewards_txt)
	_level_payout_ready = false
	get_tree().paused = true
	call_deferred("_begin_level_complete_fly")


func _on_pause_button_pressed() -> void:
	if game_over:
		return
	if level_complete_screen.visible:
		return
	if pause_screen.visible:
		_on_pause_resume_pressed()
		return
	AudioService.play_button_click()
	get_tree().paused = true
	pause_screen.show_pause()


func _on_pause_resume_pressed() -> void:
	AudioService.play_button_click()
	get_tree().paused = false
	pause_screen.hide_pause()
	how_to_play_screen.hide_help()


func _on_pause_settings_pressed() -> void:
	AudioService.play_button_click()
	settings_screen.open_settings()


func _on_pause_how_to_play_pressed() -> void:
	AudioService.play_button_click()
	how_to_play_screen.show_help()


func _on_pause_main_menu_pressed() -> void:
	AudioService.play_button_click()
	_save_progress_file()
	_clear_pause_state()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_booster_freeze_pressed() -> void:
	if game_over or level_complete_screen.visible or ingame_freeze <= 0 or _freeze_timer > 0.0:
		return
	AudioService.play_button_click()
	ingame_freeze -= 1
	_freeze_timer = 5.0
	_flash_booster("Glacier — drops hold still!")
	_save_progress_file()
	_refresh_ui()


func _on_booster_slow_pressed() -> void:
	if game_over or level_complete_screen.visible or ingame_slowmo <= 0 or _ingame_slow_timer > 0.0:
		return
	AudioService.play_button_click()
	ingame_slowmo -= 1
	_ingame_slow_timer = 8.0
	_flash_booster("Driftward — gentle falls!")
	_save_progress_file()
	_refresh_ui()


func _on_booster_magnet_pressed() -> void:
	if game_over or level_complete_screen.visible or ingame_magnet <= 0 or _magnet_timer > 0.0:
		return
	AudioService.play_button_click()
	ingame_magnet -= 1
	_magnet_timer = 8.0
	if _magnet_target_x < 0.0:
		_magnet_target_x = maxf(get_viewport_rect().size.x * 0.5, 120.0)
	_flash_booster("Tidepull — gleams lean your way!")
	_save_progress_file()
	_refresh_ui()


func _on_booster_shield_hud_pressed() -> void:
	if game_over or level_complete_screen.visible or booster_shield <= 0:
		return
	AudioService.play_button_click()
	booster_shield -= 1
	_shield_blocks_next += 1
	_flash_booster("Aegis primed — next danger is soaked!")
	_save_progress_file()
	_refresh_ui()


func _exit_tree() -> void:
	if not game_over:
		_save_progress_file()


func _lives_text() -> String:
	var hearts := ""
	for _i in range(max(lives, 0)):
		hearts += HEART_EMOJI
	return "Lives: %d/%d %s" % [lives, _effective_max_lives, hearts]


func _level_help_text() -> String:
	var combo_hint := "Combo: every %d gleams in a row steps up the multiplier." % COMBO_STEP
	var dn: String = str(_cached_cfg.get("difficulty_name", "River"))
	var ts: int = int(_cached_cfg.get("target_score", 100))
	var tc: int = int(_cached_cfg.get("target_coins", 20))
	var core := "Level %d (%s) — reach +%d pts or %d level coins. %s" % [get_level(), dn, ts, tc, combo_hint]
	if bombs_enabled():
		return core + " Bombs are live — never tap fuses."
	return core


func _apply_level_from_map_selection(selected: int) -> void:
	var lvl: int = clampi(selected, 1, furthest_level_unlocked)
	progression_level = lvl
	score = LevelProgression.get_cumulative_score_through_level(progression_level - 1)
	level_coins_collected = 0
	_level_score_at_start = score
	_begin_level_segment(false)
	_save_progress_file()


func _load_progress_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		best_score = 0
		vault_coins = 0
		score = 0
		progression_level = 1
		furthest_level_unlocked = 1
		_level_score_at_start = 0
		booster_lightning = 5
		booster_hourglass = 4
		booster_shield = 2
		booster_bomb_clear = 3
		booster_start_slow = 3
		ingame_freeze = 2
		ingame_slowmo = 2
		ingame_magnet = 2
		retry_charges = MAX_RETRY_CHARGES
		retry_block_until_unix = 0
		stat_gleams_collected = 0
		stat_bombs_dodged = 0
		stat_max_combo_streak = 0
		return
	best_score = int(cfg.get_value(SAVE_SECTION, KEY_BEST, 0))
	vault_coins = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_SAVED_SCORE, 0)))
	if cfg.has_section_key(SAVE_SECTION, KEY_SESSION_SCORE):
		score = int(cfg.get_value(SAVE_SECTION, KEY_SESSION_SCORE, 0))
	else:
		score = vault_coins
	furthest_level_unlocked = clampi(int(cfg.get_value(SAVE_SECTION, KEY_FURTHEST_LEVEL, cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1))), 1, 999999)
	progression_level = int(cfg.get_value(SAVE_SECTION, KEY_CURRENT_LEVEL, cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1)))
	furthest_level_unlocked = maxi(furthest_level_unlocked, progression_level)
	progression_level = clampi(progression_level, 1, furthest_level_unlocked)
	if cfg.has_section_key(SAVE_SECTION, KEY_LEVEL_SCORE_FLOOR):
		_level_score_at_start = int(cfg.get_value(SAVE_SECTION, KEY_LEVEL_SCORE_FLOOR, 0))
	else:
		_level_score_at_start = score
	if score < _level_score_at_start:
		score = _level_score_at_start
	booster_lightning = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_LIGHTNING, 5)), 0, 99)
	booster_hourglass = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_HOURGLASS, 4)), 0, 99)
	booster_shield = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_SHIELD, 2)), 0, 99)
	booster_bomb_clear = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_BOMB_CLEAR, 3)), 0, 99)
	booster_start_slow = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_START_SLOW, 3)), 0, 99)
	ingame_freeze = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_INGAME_FREEZE, 2)), 0, 99)
	ingame_slowmo = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_INGAME_SLOWMO, 2)), 0, 99)
	ingame_magnet = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_INGAME_MAGNET, 2)), 0, 99)
	retry_charges = clampi(int(cfg.get_value(SAVE_SECTION, KEY_RETRY_CHARGES, MAX_RETRY_CHARGES)), 0, MAX_RETRY_CHARGES)
	retry_block_until_unix = int(cfg.get_value(SAVE_SECTION, KEY_RETRY_BLOCK_UNTIL, 0))
	if retry_charges <= 0 and retry_block_until_unix <= 0:
		retry_charges = MAX_RETRY_CHARGES
		retry_block_until_unix = 0
	stat_gleams_collected = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_GLEAMS, 0)))
	stat_bombs_dodged = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_BOMBS_DODGED, 0)))
	stat_max_combo_streak = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_MAX_COMBO, 0)))
	_update_retry_refill_if_needed()


func _save_progress_file() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if score > best_score:
		best_score = score
	cfg.set_value(SAVE_SECTION, KEY_BEST, best_score)
	cfg.set_value(SAVE_SECTION, KEY_SAVED_SCORE, vault_coins)
	cfg.set_value(SAVE_SECTION, KEY_SESSION_SCORE, score)
	cfg.set_value(SAVE_SECTION, KEY_FURTHEST_LEVEL, furthest_level_unlocked)
	cfg.set_value(SAVE_SECTION, KEY_CURRENT_LEVEL, progression_level)
	cfg.set_value(SAVE_SECTION, KEY_LEVEL_SCORE_FLOOR, _level_score_at_start)
	cfg.set_value(SAVE_SECTION, KEY_PROGRESSION, furthest_level_unlocked)
	cfg.set_value(SAVE_SECTION, KEY_BOOST_LIGHTNING, booster_lightning)
	cfg.set_value(SAVE_SECTION, KEY_BOOST_HOURGLASS, booster_hourglass)
	cfg.set_value(SAVE_SECTION, KEY_BOOST_SHIELD, booster_shield)
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_BOMB_CLEAR, booster_bomb_clear)
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_START_SLOW, booster_start_slow)
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_INGAME_FREEZE, ingame_freeze)
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_INGAME_SLOWMO, ingame_slowmo)
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_INGAME_MAGNET, ingame_magnet)
	cfg.set_value(SAVE_SECTION, KEY_RETRY_CHARGES, retry_charges)
	cfg.set_value(SAVE_SECTION, KEY_RETRY_BLOCK_UNTIL, retry_block_until_unix)
	cfg.set_value(SAVE_SECTION, KEY_STAT_GLEAMS, stat_gleams_collected)
	cfg.set_value(SAVE_SECTION, KEY_STAT_BOMBS_DODGED, stat_bombs_dodged)
	cfg.set_value(SAVE_SECTION, KEY_STAT_MAX_COMBO, stat_max_combo_streak)
	cfg.save(SAVE_PATH)


func _refresh_booster_bar() -> void:
	if booster_freeze_btn == null:
		return
	var busy: bool = game_over or level_complete_screen.visible or get_tree().paused
	var ul_f: bool = LevelProgression.is_booster_unlocked("ingame_freeze", furthest_level_unlocked)
	var ul_m: bool = LevelProgression.is_booster_unlocked("ingame_magnet", furthest_level_unlocked)
	var ul_sh: bool = LevelProgression.is_booster_unlocked("ingame_shield", furthest_level_unlocked)
	booster_freeze_btn.disabled = busy or ingame_freeze <= 0 or _freeze_timer > 0.0 or not ul_f
	booster_slow_btn.disabled = busy or ingame_slowmo <= 0 or _ingame_slow_timer > 0.0
	booster_magnet_btn.disabled = busy or ingame_magnet <= 0 or _magnet_timer > 0.0 or not ul_m
	booster_shield_btn.disabled = busy or booster_shield <= 0 or not ul_sh
	booster_freeze_btn.text = "❄️\n%d" % ingame_freeze
	booster_slow_btn.text = "🌀\n%d" % ingame_slowmo
	booster_magnet_btn.text = "🧲\n%d" % ingame_magnet
	booster_shield_btn.text = "🛡️\n%d" % booster_shield
	booster_freeze_btn.modulate = Color(1, 1, 1, 1) if ul_f else Color(0.55, 0.55, 0.6, 0.85)
	booster_magnet_btn.modulate = Color(1, 1, 1, 1) if ul_m else Color(0.55, 0.55, 0.6, 0.85)
	booster_shield_btn.modulate = Color(1, 1, 1, 1) if ul_sh else Color(0.55, 0.55, 0.6, 0.85)


func _refresh_ui() -> void:
	_refresh_booster_bar()
	if controls_label:
		if bombs_enabled():
			controls_label.text = "Tap a coin or gem to collect it. Tap a red bomb = mistake (loses a life)."
		else:
			controls_label.text = "Tap a coin or gem to collect it. (No bombs yet — just catch the good drops.)"
	if score_label:
		score_label.text = "Score: %d" % score
	if vault_coins_label:
		vault_coins_label.text = "🪙 Vault: %d" % vault_coins
	if level_coins_hud_label:
		level_coins_hud_label.text = "Level coins: %d" % level_coins_collected
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
	if not game_over:
		_sync_collectible_slots()
		_try_offer_level_gate()
	if level_label:
		var ts: int = int(_cached_cfg.get("target_score", 1))
		var tc: int = int(_cached_cfg.get("target_coins", 1))
		var dpts: int = maxi(0, score - _level_score_at_start)
		var dn: String = str(_cached_cfg.get("difficulty_name", ""))
		var time_bit: String = ""
		if _level_time_remaining > 0.0:
			time_bit = "  ·  %.0fs" % _level_time_remaining
		level_label.text = "Lv %d %s  ·  %d/%d pts  ·  %d/%d coins%s" % [get_level(), dn, dpts, ts, level_coins_collected, tc, time_bit]
	if miss_summary_label:
		miss_summary_label.text = "Missed coins: %d" % missed_coins
	if warning_label:
		if _booster_feedback_timer > 0.0 and not _booster_feedback_text.is_empty():
			warning_label.add_theme_color_override("font_color", Color(0.55, 0.98, 0.78))
			warning_label.text = _booster_feedback_text
		elif level_complete_screen.visible:
			warning_label.text = ""
		elif game_over:
			warning_label.text = "Level failed — Retry or ✕ for menu."
		elif lives <= 1:
			warning_label.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
			warning_label.text = "Last life! Tap coins & gems only — bombs are a mistake. Strip still costs a life. " + _level_help_text()
		elif lives <= 3:
			warning_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
			warning_label.text = "Low lives — " + _level_help_text()
		else:
			warning_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.8))
			warning_label.text = _level_help_text()
