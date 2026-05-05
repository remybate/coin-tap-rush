extends Control
class_name EventsPopup

signal closed

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION_PROGRESS: String = "progress"
const SAVE_SECTION_EVENTS: String = "events"

const KEY_SAVED_SCORE: String = "saved_score"
const KEY_STAT_GLEAMS: String = "stat_gleams_collected"
const KEY_STAT_BOMBS_DODGED: String = "stat_bombs_dodged"

const KEY_DAY_INDEX: String = "day_index"
const KEY_DAY_BASE_COINS: String = "day_base_coins"
const KEY_DAY_BASE_GLEAMS: String = "day_base_gleams"
const KEY_WEEK_INDEX: String = "week_index"
const KEY_WEEK_BASE_BOMBS: String = "week_base_bombs"

@onready var _close_x: Button = $CloseX
@onready var _close_btn: Button = $Center/Panel/Margin/Root/Footer/CloseBtn
@onready var _title: Label = $Center/Panel/Margin/Root/Title
@onready var _subtitle: Label = $Center/Panel/Margin/Root/Subtitle
@onready var _items_host: VBoxContainer = $Center/Panel/Margin/Root/Scroll/Margin/ItemsHost


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_close_btn.pressed.connect(_on_close)


func open_bonus() -> void:
	_present("Bonus board", "Short-run boosts and streak pushes. Progress resets on the vault’s clock — chase the glow before the hour flips.")
	visible = true


func open_events() -> void:
	_present("Vault events", "Timed challenges rotate through the treasure halls. Each event shows its own goal, progress, and reward stamp.")
	visible = true


func close_popup() -> void:
	visible = false
	closed.emit()


func _on_close() -> void:
	AudioService.play_button_click()
	close_popup()


func _present(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_rebuild()


func _today_day_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400)


func _week_index() -> int:
	return int(_today_day_index() / 7)


func _seconds_to_next_midnight() -> int:
	var now: int = int(Time.get_unix_time_from_system())
	return maxi(0, 86400 - (now % 86400))


func _ensure_event_baselines(cfg: ConfigFile) -> Dictionary:
	var day_idx: int = _today_day_index()
	var week_idx: int = _week_index()

	var coins: int = maxi(0, int(cfg.get_value(SAVE_SECTION_PROGRESS, KEY_SAVED_SCORE, 0)))
	var gleams: int = maxi(0, int(cfg.get_value(SAVE_SECTION_PROGRESS, KEY_STAT_GLEAMS, 0)))
	var bombs: int = maxi(0, int(cfg.get_value(SAVE_SECTION_PROGRESS, KEY_STAT_BOMBS_DODGED, 0)))

	var saved_day: int = int(cfg.get_value(SAVE_SECTION_EVENTS, KEY_DAY_INDEX, -1))
	if saved_day != day_idx:
		cfg.set_value(SAVE_SECTION_EVENTS, KEY_DAY_INDEX, day_idx)
		cfg.set_value(SAVE_SECTION_EVENTS, KEY_DAY_BASE_COINS, coins)
		cfg.set_value(SAVE_SECTION_EVENTS, KEY_DAY_BASE_GLEAMS, gleams)

	var saved_week: int = int(cfg.get_value(SAVE_SECTION_EVENTS, KEY_WEEK_INDEX, -1))
	if saved_week != week_idx:
		cfg.set_value(SAVE_SECTION_EVENTS, KEY_WEEK_INDEX, week_idx)
		cfg.set_value(SAVE_SECTION_EVENTS, KEY_WEEK_BASE_BOMBS, bombs)

	cfg.save(SAVE_PATH)

	return {
		"coins": coins,
		"gleams": gleams,
		"bombs": bombs,
		"day_base_coins": maxi(0, int(cfg.get_value(SAVE_SECTION_EVENTS, KEY_DAY_BASE_COINS, coins))),
		"day_base_gleams": maxi(0, int(cfg.get_value(SAVE_SECTION_EVENTS, KEY_DAY_BASE_GLEAMS, gleams))),
		"week_base_bombs": maxi(0, int(cfg.get_value(SAVE_SECTION_EVENTS, KEY_WEEK_BASE_BOMBS, bombs))),
	}


func _is_weekend() -> bool:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	# Godot weekday: 0=Sunday ... 6=Saturday
	var wd: int = int(dt.get("weekday", 0))
	return wd == 0 or wd == 6


func _rebuild() -> void:
	for c in _items_host.get_children():
		c.queue_free()

	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var st: Dictionary = _ensure_event_baselines(cfg)

	var coins_today: int = maxi(0, int(st["coins"]) - int(st["day_base_coins"]))
	var gleams_today: int = maxi(0, int(st["gleams"]) - int(st["day_base_gleams"]))
	var bombs_week: int = maxi(0, int(st["bombs"]) - int(st["week_base_bombs"]))
	var t_midnight: int = _seconds_to_next_midnight()

	var weekend_on: bool = _is_weekend()
	var events: Array[Dictionary] = [
		{
			"title": "Double Coins Weekend",
			"desc": "The brass counter clicks twice. Coin earnings are doubled while the weekend lamps are lit.",
			"active": weekend_on,
			"progress": mini(coins_today, 1200),
			"goal": 1200,
			"meta": ("Ends in %s" % _fmt_hms(t_midnight)) if weekend_on else "Returns on the weekend",
			"reward": "Reward: +1 Gleam Drift (⚡)",
		},
		{
			"title": "Treasure Hunt",
			"desc": "Today’s scavenger route: scoop gleams cleanly and keep your rhythm. Every tap feeds the hunt.",
			"active": true,
			"progress": mini(gleams_today, 150),
			"goal": 150,
			"meta": "Resets in %s" % _fmt_hms(t_midnight),
			"reward": "Reward: +300 coins",
		},
		{
			"title": "Bomb Dodge Challenge",
			"desc": "Let fuses slide past the danger line. No panic taps — just calm drift and clean lanes.",
			"active": true,
			"progress": mini(bombs_week, 30),
			"goal": 30,
			"meta": "Weekly tally (resets on the vault week)",
			"reward": "Reward: +1 Shield plate (🛡️)",
		},
	]

	for e in events:
		_items_host.add_child(_make_event_row(e))


func _make_event_row(e: Dictionary) -> PanelContainer:
	var title: String = str(e["title"])
	var desc: String = str(e["desc"])
	var reward: String = str(e["reward"])
	var meta: String = str(e["meta"])
	var cur: int = int(e["progress"])
	var goal: int = maxi(1, int(e["goal"]))
	var active: bool = bool(e["active"])
	var ratio: float = clampf(float(cur) / float(goal), 0.0, 1.0)

	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.07, 0.09, 0.16, 0.95)
		sb.border_color = Color(0.95, 0.7, 0.35, 0.75)
	else:
		sb.bg_color = Color(0.05, 0.06, 0.1, 0.92)
		sb.border_color = Color(0.45, 0.44, 0.55, 0.45)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", sb)
	if not active:
		row.modulate = Color(0.75, 0.76, 0.84, 1)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	row.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)

	var t := Label.new()
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(1, 0.88, 0.45, 1) if active else Color(0.9, 0.9, 1, 0.95))
	top.add_child(t)

	var badge := Label.new()
	badge.text = "LIVE" if active else "SOON"
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", Color(0.55, 1.0, 0.72, 1) if active else Color(0.8, 0.82, 0.92, 0.85))
	top.add_child(badge)

	var ld := Label.new()
	ld.text = desc
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ld.add_theme_font_size_override("font_size", 16)
	ld.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0, 0.92))
	v.add_child(ld)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = float(goal)
	bar.value = float(cur)
	bar.custom_minimum_size = Vector2(0, 22)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.06, 0.1, 1)
	_style_radius_8(bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.65, 0.28, 1) if ratio > 0.01 else Color(0.4, 0.55, 0.95, 1)
	_style_radius_8(fill)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	v.add_child(bar)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 10)
	v.add_child(meta_row)

	var meta_lbl := Label.new()
	meta_lbl.text = meta
	meta_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_lbl.add_theme_font_size_override("font_size", 14)
	meta_lbl.add_theme_color_override("font_color", Color(0.78, 0.85, 0.98, 0.85))
	meta_row.add_child(meta_lbl)

	var nums := Label.new()
	nums.text = "%d / %d" % [cur, goal]
	nums.add_theme_font_size_override("font_size", 14)
	nums.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.95))
	meta_row.add_child(nums)

	var rw := Label.new()
	rw.text = reward
	rw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rw.add_theme_font_size_override("font_size", 15)
	rw.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85, 1))
	v.add_child(rw)

	return row


func _style_radius_8(sb: StyleBoxFlat) -> void:
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8


func _fmt_hms(secs: int) -> String:
	var s: int = maxi(0, secs)
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	var sec: int = s % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, sec]
	return "%02d:%02d" % [m, sec]

