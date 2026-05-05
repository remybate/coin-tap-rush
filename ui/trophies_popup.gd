extends Control
class_name TrophiesPopup

signal closed

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_PROGRESSION: String = "saved_progression_level"
const KEY_STAT_GLEAMS: String = "stat_gleams_collected"
const KEY_STAT_BOMBS_DODGED: String = "stat_bombs_dodged"
const KEY_STAT_MAX_COMBO: String = "stat_max_combo_streak"

@onready var _close_x: Button = $CloseX
@onready var _close_btn: Button = $Center/Panel/Margin/Root/Footer/CloseBtn
@onready var _items_host: VBoxContainer = $Center/Panel/Margin/Root/Scroll/Margin/ItemsHost


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_close_btn.pressed.connect(_on_close)


func open_trophies() -> void:
	_refresh_list()
	visible = true


func close_trophies() -> void:
	visible = false
	closed.emit()


func _on_close() -> void:
	AudioService.play_button_click()
	close_trophies()


func _refresh_list() -> void:
	for c in _items_host.get_children():
		c.queue_free()

	var cfg := ConfigFile.new()
	var prog: int = 1
	var gleams: int = 0
	var bombs_dodged: int = 0
	var combo_best: int = 0
	if cfg.load(SAVE_PATH) == OK:
		prog = maxi(1, int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1)))
		gleams = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_GLEAMS, 0)))
		bombs_dodged = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_BOMBS_DODGED, 0)))
		combo_best = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_MAX_COMBO, 0)))

	var defs: Array[Dictionary] = [
		{
			"id": "hundred_gleams",
			"title": "River of a Hundred Gleams",
			"desc": "Collect 100 coins, gems, or diamond taps in the rush. Each clean tap adds to your vault tally.",
			"current": mini(gleams, 100),
			"goal": 100,
		},
		{
			"id": "level_ten",
			"title": "Tenth Arch of the Vault",
			"desc": "Reach progression level 10 — keep clearing score goals and marching deeper into the map.",
			"current": mini(prog, 10),
			"goal": 10,
		},
		{
			"id": "bombs_twenty",
			"title": "Fuse Line Drifter",
			"desc": "Let 20 bombs scroll past the danger line without tapping them. Cool nerves, warmer vault.",
			"current": mini(bombs_dodged, 20),
			"goal": 20,
		},
		{
			"id": "combo_ten",
			"title": "Ten-Beat Shine Chain",
			"desc": "Chain 10 good taps in a row without a miss or bomb tap. Rhythm beats chaos.",
			"current": mini(combo_best, 10),
			"goal": 10,
		},
	]

	for d in defs:
		_items_host.add_child(_make_trophy_row(d))


func _make_trophy_row(d: Dictionary) -> PanelContainer:
	var title: String = d["title"]
	var desc: String = d["desc"]
	var cur: int = int(d["current"])
	var goal: int = int(d["goal"])
	var earned: bool = cur >= goal
	var ratio: float = 0.0 if goal <= 0 else clampf(float(cur) / float(goal), 0.0, 1.0)

	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	if earned:
		sb.bg_color = Color(0.1, 0.14, 0.08, 0.95)
		sb.border_color = Color(1, 0.82, 0.35, 0.95)
	else:
		sb.bg_color = Color(0.06, 0.08, 0.14, 0.92)
		sb.border_color = Color(0.45, 0.35, 0.62, 0.55)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", sb)
	if not earned:
		row.modulate = Color(0.82, 0.86, 0.95, 1.0)

	var margin := MarginContainer.new()
	row.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)

	var status_icon := Label.new()
	status_icon.text = "✓" if earned else "🔒"
	status_icon.add_theme_font_size_override("font_size", 22)
	top.add_child(status_icon)

	var t := Label.new()
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", 21)
	t.add_theme_color_override("font_color", Color(1, 0.9, 0.55, 1) if earned else Color(0.92, 0.82, 1.0, 1))
	top.add_child(t)

	var state := Label.new()
	if earned:
		state.text = "Unlocked"
		state.add_theme_color_override("font_color", Color(0.55, 1.0, 0.72, 1))
	else:
		state.text = "Locked"
		state.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88, 0.85))
	state.add_theme_font_size_override("font_size", 16)
	top.add_child(state)

	var ld := Label.new()
	ld.text = desc
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ld.add_theme_font_size_override("font_size", 16)
	ld.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.9))
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
	if earned:
		fill.bg_color = Color(0.35, 0.92, 0.55, 1)
	elif ratio > 0.01:
		fill.bg_color = Color(0.95, 0.65, 0.28, 1)
	else:
		fill.bg_color = Color(0.4, 0.55, 0.95, 1)
	_style_radius_8(fill)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	v.add_child(bar)

	var nums := Label.new()
	nums.text = "%s / %d  (%d%%)" % [_fmt_int(cur), goal, int(round(ratio * 100.0))]
	nums.add_theme_font_size_override("font_size", 16)
	nums.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.95))
	v.add_child(nums)

	return row


func _fmt_int(n: int) -> String:
	return str(maxi(0, n))


func _style_radius_8(sb: StyleBoxFlat) -> void:
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
