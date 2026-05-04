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
const MAX_RETRY_CHARGES: int = 5
const MAX_LIVES_DISPLAY: int = 5

@onready var how_to_play: HowToPlayScreen = $HowToPlayLayer
@onready var settings: SettingsScreen = $SettingsLayer
@onready var daily_bonus: DailyBonusScreen = $DailyBonusLayer
@onready var stub_dialog: AcceptDialog = $StubDialog
@onready var coin_value_label: Label = $MainColumn/VBox/TopBar/CoinPill/Margin/HBox/CoinValue
@onready var lives_value_label: Label = $MainColumn/VBox/TopBar/LivesPill/Margin/HBox/LivesValue
@onready var play_button: Button = $MainColumn/VBox/PlaySection/PlayButton


func _ready() -> void:
	how_to_play.visible = false
	settings.visible = false
	daily_bonus.hide_bonus()
	daily_bonus.bonus_claimed.connect(_on_daily_bonus_claimed)
	_clear_stale_retry_lock_in_save()
	_refresh_currency_ui()
	_try_auto_daily_bonus()


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
	daily_bonus.show_for_day(_daily_day_number_for_popup())


func _open_daily_bonus_flow() -> void:
	AudioService.play_button_click()
	var st: Dictionary = _read_daily_state()
	var today: int = _today_day_index()
	if int(st["last_day"]) == today:
		_show_stub("Daily Reward", "You already claimed today's reward. Come back tomorrow!")
		return
	daily_bonus.show_for_day(_daily_day_number_for_popup())


func _on_daily_bonus_claimed(amount: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var today: int = _today_day_index()
	var last_day: int = int(cfg.get_value(SAVE_SECTION, KEY_DAILY_LAST_CLAIM_DAY, -1))
	var streak: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_DAILY_STREAK, 0)))
	if last_day == today - 1:
		streak = mini(streak + 1, 7)
	else:
		streak = 1
	cfg.set_value(SAVE_SECTION, KEY_DAILY_LAST_CLAIM_DAY, today)
	cfg.set_value(SAVE_SECTION, KEY_DAILY_STREAK, streak)
	var bank: int = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_SAVED_SCORE, 0)))
	bank += maxi(0, amount)
	cfg.set_value(SAVE_SECTION, KEY_SAVED_SCORE, bank)
	var best: int = int(cfg.get_value(SAVE_SECTION, KEY_BEST, 0))
	if bank > best:
		cfg.set_value(SAVE_SECTION, KEY_BEST, bank)
	cfg.save(SAVE_PATH)
	_refresh_currency_ui()


func _show_stub(title: String, message: String) -> void:
	stub_dialog.title = title
	stub_dialog.dialog_text = message
	stub_dialog.popup_centered()


func _on_play_pressed() -> void:
	AudioService.play_button_click()
	get_tree().change_scene_to_file(LEVEL_MAP_SCENE)


func _on_profile_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Profile", "Avatars and nicknames — coming soon!")


func _on_top_settings_pressed() -> void:
	AudioService.play_button_click()
	settings.open_settings()


func _on_side_daily_pressed() -> void:
	_open_daily_bonus_flow()


func _on_side_shop_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Shop", "Treasure deals and boost packs — coming soon!")


func _on_side_bonus_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Bonus", "Limited bonus rounds — coming soon!")


func _on_side_events_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Events", "Seasonal challenges — coming soon!")


func _on_nav_shop_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Shop", "Open the treasure shop — coming soon!")


func _on_nav_trophy_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Trophies", "Your achievements wall — coming soon!")


func _on_nav_home_pressed() -> void:
	AudioService.play_button_click()


func _on_nav_rewards_pressed() -> void:
	_open_daily_bonus_flow()


func _on_nav_cards_pressed() -> void:
	AudioService.play_button_click()
	_show_stub("Cards", "Collectible rush cards — coming soon!")
