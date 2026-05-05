extends Control

const LEVEL_MAP_SCENE: String = "res://level_map.tscn"
const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_BEST: String = "best_score"
const KEY_SAVED_SCORE: String = "saved_score"
const KEY_RETRY_CHARGES: String = "retry_charges"
const KEY_RETRY_BLOCK_UNTIL: String = "retry_block_until_unix"
const KEY_DAILY_LAST_CLAIM_DAY: String = "daily_bonus_last_claim_day"
const KEY_DAILY_STREAK: String = "daily_bonus_streak"
const KEY_BOOST_LIGHTNING: String = "booster_lightning"
const KEY_BOOST_HOURGLASS: String = "booster_hourglass"
const KEY_BOOST_SHIELD: String = "booster_shield"
const MAX_RETRY_CHARGES: int = 5
const MAX_LIVES_DISPLAY: int = 5

@onready var how_to_play: HowToPlayScreen = $HowToPlayLayer
@onready var settings: SettingsScreen = $SettingsLayer
@onready var daily_bonus: DailyBonusScreen = $DailyBonusLayer
@onready var stub_dialog: AcceptDialog = $StubDialog
@onready var simple_popup: SimplePopup = $SimplePopupLayer
## Shop/trophy scenes use `shop_popup.gd` / `trophies_popup.gd` — typed as Node so main menu parses even if global class registration is late.
@onready var shop_popup: Node = $ShopPopupLayer
@onready var trophies_popup: Node = $TrophiesPopupLayer
@onready var cards_popup: Node = $CardsPopupLayer
@onready var events_popup: Node = $EventsPopupLayer
@onready var coin_value_label: Label = $MainColumn/VBox/TopBar/CoinPill/Margin/HBox/CoinValue
@onready var lives_value_label: Label = $MainColumn/VBox/TopBar/LivesPill/Margin/HBox/LivesValue
@onready var play_button: Button = $MainColumn/VBox/PlaySection/PlayButton
@onready var _sparkle_host: Control = $SparkleField

var _sp_nodes: Array[TextureRect] = []
var _sp_phase: Array[float] = []
var _sp_base: Array[Vector2] = []
var _amb_t: float = 0.0
var _play_bounce_t: float = 0.0


func _ready() -> void:
	how_to_play.visible = false
	settings.visible = false
	daily_bonus.hide_bonus()
	daily_bonus.claim_pressed.connect(_on_daily_vault_claimed)
	settings.progress_reset.connect(_on_progress_reset)
	if shop_popup != null and shop_popup.has_signal("toast_requested"):
		shop_popup.connect("toast_requested", Callable(self, "_open_popup"))
	_clear_stale_retry_lock_in_save()
	_refresh_currency_ui()
	_try_auto_daily_bonus()
	_build_menu_sparkles()
	set_process(true)


func _process(delta: float) -> void:
	_amb_t += delta
	_play_bounce_t += delta
	if play_button != null and is_instance_valid(play_button):
		var sb: float = 1.0 + 0.032 * sin(_play_bounce_t * 2.55)
		play_button.pivot_offset = play_button.size * 0.5
		play_button.scale = Vector2(sb, sb)
	var i := 0
	while i < _sp_nodes.size():
		var tr: TextureRect = _sp_nodes[i]
		if not is_instance_valid(tr):
			_sp_nodes.remove_at(i)
			_sp_phase.remove_at(i)
			_sp_base.remove_at(i)
			continue
		var base: Vector2 = _sp_base[i]
		tr.position = base + Vector2(sin(_amb_t * 0.9 + _sp_phase[i]) * 3.0, cos(_amb_t * 0.75 + _sp_phase[i]) * 2.5)
		var a: float = 0.22 + 0.2 * sin(_amb_t * 1.25 + _sp_phase[i])
		tr.modulate.a = clampf(a, 0.12, 0.45)
		i += 1


func _build_menu_sparkles() -> void:
	if _sparkle_host == null:
		return
	var tex: Texture2D = load("res://ui/map_art/sparkle.svg") as Texture2D
	if tex == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var w: float = maxf(get_viewport_rect().size.x, 400.0)
	var h: float = maxf(get_viewport_rect().size.y, 600.0)
	for j in 10:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(20, 20)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var p := Vector2(rng.randf_range(16.0, w - 36.0), rng.randf_range(72.0, h - 260.0))
		tr.position = p
		tr.modulate = Color(1, 1, 0.92, rng.randf_range(0.25, 0.42))
		_sparkle_host.add_child(tr)
		_sp_nodes.append(tr)
		_sp_phase.append(rng.randf() * TAU)
		_sp_base.append(p)


func _notification(what: int) -> void:
	# Can run before @onready assigns node paths — avoid touching labels until ready.
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and is_node_ready():
		_refresh_currency_ui()


## Older saves may still have a cooldown; strip it so Play is never blocked.
func _clear_stale_retry_lock_in_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	cfg.set_value(SAVE_SECTION, KEY_RETRY_CHARGES, MAX_RETRY_CHARGES)
	cfg.set_value(SAVE_SECTION, KEY_RETRY_BLOCK_UNTIL, 0)
	cfg.save(SAVE_PATH)


func _refresh_currency_ui() -> void:
	if coin_value_label == null or lives_value_label == null:
		return
	var cfg := ConfigFile.new()
	var coins: int = 0
	if cfg.load(SAVE_PATH) == OK:
		coins = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_SAVED_SCORE, 0)))
	coin_value_label.text = _fmt_num(coins)
	lives_value_label.text = str(MAX_LIVES_DISPLAY)


func _fmt_num(n: int) -> String:
	return str(maxi(0, n))


func _today_day_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400)


func _read_daily_state() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {"last_day": -1, "streak": 0}
	return {
		"last_day": int(cfg.get_value(SAVE_SECTION, KEY_DAILY_LAST_CLAIM_DAY, -1)),
		"streak": maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_DAILY_STREAK, 0)))
	}


func _daily_day_number_for_popup() -> int:
	var st: Dictionary = _read_daily_state()
	var today: int = _today_day_index()
	var last_day: int = int(st["last_day"])
	var streak: int = int(st["streak"])
	if last_day == today - 1:
		return mini(streak + 1, 7)
	return 1


func _try_auto_daily_bonus() -> void:
	var st: Dictionary = _read_daily_state()
	if int(st["last_day"]) == _today_day_index():
		return
	var next_day: int = _daily_day_number_for_popup()
	daily_bonus.present(next_day, true, int(st["streak"]))


func _open_daily_bonus_flow() -> void:
	AudioService.play_button_click()
	var st: Dictionary = _read_daily_state()
	var today: int = _today_day_index()
	var can_claim: bool = int(st["last_day"]) != today
	var streak_saved: int = int(st["streak"])
	var next_day: int = _daily_day_number_for_popup() if can_claim else streak_saved
	daily_bonus.present(next_day, can_claim, streak_saved)


func _daily_reward_payload(day: int) -> Dictionary:
	match clampi(day, 1, 7):
		1:
			return {"coins": 100}
		2:
			return {"hourglass": 1}
		3:
			return {"coins": 250}
		4:
			return {"bomb_clear": 1}
		5:
			return {"coins": 500}
		6:
			return {"shield": 1}
		7:
			return {"coins": 800, "lightning": 1, "hourglass": 1, "shield": 1, "bomb_clear": 1, "start_slow": 1}
		_:
			return {}


func _grant_daily_rewards_for_day(cfg: ConfigFile, day: int) -> void:
	var r: Dictionary = _daily_reward_payload(day)
	var bank: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_SAVED_SCORE, 0)))
	bank += int(r.get("coins", 0))
	cfg.set_value(SAVE_SECTION, KEY_SAVED_SCORE, bank)
	var best: int = int(cfg.get_value(SAVE_SECTION, KEY_BEST, 0))
	if bank > best:
		cfg.set_value(SAVE_SECTION, KEY_BEST, bank)
	var li: int = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_LIGHTNING, 5)), 0, 99)
	li += int(r.get("lightning", 0))
	cfg.set_value(SAVE_SECTION, KEY_BOOST_LIGHTNING, li)
	var hg: int = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_HOURGLASS, 4)), 0, 99)
	hg += int(r.get("hourglass", 0))
	cfg.set_value(SAVE_SECTION, KEY_BOOST_HOURGLASS, hg)
	var sh: int = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_SHIELD, 0)), 0, 99)
	sh += int(r.get("shield", 0))
	cfg.set_value(SAVE_SECTION, KEY_BOOST_SHIELD, sh)
	var bc: int = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_BOMB_CLEAR, 3)), 0, 99)
	bc += int(r.get("bomb_clear", 0))
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_BOMB_CLEAR, bc)
	var ss: int = clampi(int(cfg.get_value(SAVE_SECTION, BoosterManager.KEY_START_SLOW, 3)), 0, 99)
	ss += int(r.get("start_slow", 0))
	cfg.set_value(SAVE_SECTION, BoosterManager.KEY_START_SLOW, ss)


func _on_daily_vault_claimed() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var today: int = _today_day_index()
	if int(cfg.get_value(SAVE_SECTION, KEY_DAILY_LAST_CLAIM_DAY, -1)) == today:
		return
	var day: int = _daily_day_number_for_popup()
	var last_day: int = int(cfg.get_value(SAVE_SECTION, KEY_DAILY_LAST_CLAIM_DAY, -1))
	var streak: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_DAILY_STREAK, 0)))
	if last_day == today - 1:
		streak = mini(streak + 1, 7)
	else:
		streak = 1
	cfg.set_value(SAVE_SECTION, KEY_DAILY_LAST_CLAIM_DAY, today)
	cfg.set_value(SAVE_SECTION, KEY_DAILY_STREAK, streak)
	_grant_daily_rewards_for_day(cfg, day)
	cfg.save(SAVE_PATH)
	_refresh_currency_ui()
	daily_bonus.hide_bonus()


func _show_stub(title: String, message: String) -> void:
	# Legacy AcceptDialog fallback (should be rare).
	stub_dialog.title = title
	stub_dialog.dialog_text = message
	stub_dialog.popup_centered()


func _open_popup(title: String, message: String) -> void:
	if simple_popup != null:
		simple_popup.open_popup(title, message)
	else:
		_show_stub(title, message)


func _on_play_pressed() -> void:
	AudioService.play_button_click()
	get_tree().change_scene_to_file(LEVEL_MAP_SCENE)


func _on_profile_pressed() -> void:
	AudioService.play_button_click()
	_open_popup(
		"Vault profile",
		"Your portrait frame, trail sparkles, and signature tap burst will live here. Customize your look between runs in a future update."
	)


func _on_top_settings_pressed() -> void:
	AudioService.play_button_click()
	settings.open_settings()


func _on_side_daily_pressed() -> void:
	_open_daily_bonus_flow()


func _on_side_shop_pressed() -> void:
	AudioService.play_button_click()
	_open_shop()


func _on_side_bonus_pressed() -> void:
	AudioService.play_button_click()
	_open_bonus()


func _on_side_events_pressed() -> void:
	AudioService.play_button_click()
	_open_events()


func _on_nav_shop_pressed() -> void:
	AudioService.play_button_click()
	_open_shop()


func _on_nav_trophy_pressed() -> void:
	AudioService.play_button_click()
	_open_trophies()


func _on_nav_home_pressed() -> void:
	AudioService.play_button_click()


func _on_nav_rewards_pressed() -> void:
	_open_daily_bonus_flow()


func _on_nav_cards_pressed() -> void:
	_open_cards()


func _open_cards() -> void:
	AudioService.play_button_click()
	if cards_popup != null and cards_popup.has_method("open_cards"):
		cards_popup.call("open_cards")
	else:
		_open_popup("Rush Reliquary", "The card vault is sealed — try again after an update.")


func _open_bonus() -> void:
	if events_popup != null and events_popup.has_method("open_bonus"):
		events_popup.call("open_bonus")
	else:
		_open_popup("Bonus board", "The bonus board is being re-inked — check back soon.")


func _open_events() -> void:
	if events_popup != null and events_popup.has_method("open_events"):
		events_popup.call("open_events")
	else:
		_open_popup("Vault events", "The event lanterns are out — check back soon.")


func _on_progress_reset() -> void:
	_refresh_currency_ui()
	daily_bonus.hide_bonus()


func _open_shop() -> void:
	if shop_popup != null and shop_popup.has_method("open_shop"):
		shop_popup.call("open_shop")
	else:
		_open_popup("Shop", "The emporium is temporarily unavailable.")


func _open_trophies() -> void:
	if trophies_popup != null and trophies_popup.has_method("open_trophies"):
		trophies_popup.call("open_trophies")
	else:
		_open_popup("Trophies", "The hall of gleams is closed for polishing.")
