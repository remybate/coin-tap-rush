extends Control

## Offline leaderboard with placeholder rivals; real stats from save for "You".

signal closed
signal trophies_requested

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_BEST: String = "best_score"
const KEY_FURTHEST: String = "furthest_level_unlocked"
const KEY_PROGRESSION: String = "saved_progression_level"

enum SortMode { BY_SCORE, BY_LEVEL }

@onready var _dim: ColorRect = $Dim
@onready var _list: VBoxContainer = $Center/Panel/Margin/VBox/Scroll/ListHost
@onready var _subtitle: Label = $Center/Panel/Margin/VBox/Subtitle
@onready var _btn_sort_score: Button = $Center/Panel/Margin/VBox/SortRow/BtnSortScore
@onready var _btn_sort_level: Button = $Center/Panel/Margin/VBox/SortRow/BtnSortLevel
@onready var _btn_trophies: Button = $Center/Panel/Margin/VBox/Footer/BtnTrophies
@onready var _close_btn: Button = $Center/Panel/Margin/VBox/Footer/CloseBtn

var _sort_mode: SortMode = SortMode.BY_SCORE
var _sort_group: ButtonGroup


func _ready() -> void:
	_sort_group = ButtonGroup.new()
	_btn_sort_score.toggle_mode = true
	_btn_sort_level.toggle_mode = true
	_btn_sort_score.button_group = _sort_group
	_btn_sort_level.button_group = _sort_group
	_btn_sort_score.button_pressed = true
	_close_btn.pressed.connect(_on_close)
	_btn_trophies.pressed.connect(_on_trophy_goals)
	_dim.gui_input.connect(_on_dim_input)
	_btn_sort_score.pressed.connect(_on_sort_score)
	_btn_sort_level.pressed.connect(_on_sort_level)
	hide()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()


func open_rank() -> void:
	_refresh_list()
	show()


func _on_close() -> void:
	AudioService.play_button_click()
	hide()
	closed.emit()


func _on_trophy_goals() -> void:
	AudioService.play_button_click()
	trophies_requested.emit()


func _on_sort_score() -> void:
	AudioService.play_button_click()
	_sort_mode = SortMode.BY_SCORE
	_refresh_list()


func _on_sort_level() -> void:
	AudioService.play_button_click()
	_sort_mode = SortMode.BY_LEVEL
	_refresh_list()


func _read_you_stats() -> Dictionary:
	var cfg := ConfigFile.new()
	var best: int = 0
	var lvl: int = 1
	if cfg.load(SAVE_PATH) == OK:
		best = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_BEST, 0)))
		var f: int = int(cfg.get_value(SAVE_SECTION, KEY_FURTHEST, -1))
		var p: int = int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1))
		lvl = clampi(f if f > 0 else p, 1, 999_999)
	return {"name": "You", "best": best, "level": lvl, "hue": 0.14, "is_you": true}


func _placeholder_roster() -> Array[Dictionary]:
	return [
		{"name": "NovaStrike", "best": 198_420, "level": 62, "hue": 0.02, "is_you": false},
		{"name": "RimGlider", "best": 176_050, "level": 55, "hue": 0.12, "is_you": false},
		{"name": "VaultQueen", "best": 154_200, "level": 51, "hue": 0.78, "is_you": false},
		{"name": "TapWizard", "best": 121_000, "level": 44, "hue": 0.55, "is_you": false},
		{"name": "CoinNomad", "best": 98_000, "level": 38, "hue": 0.33, "is_you": false},
		{"name": "FuseDancer", "best": 84_200, "level": 35, "hue": 0.08, "is_you": false},
		{"name": "Sparkline", "best": 71_200, "level": 31, "hue": 0.45, "is_you": false},
	]


func _refresh_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	_refresh_sort_visuals()
	if _sort_mode == SortMode.BY_SCORE:
		_subtitle.text = "Offline demo rivals · sorted by best run score"
	else:
		_subtitle.text = "Offline demo rivals · sorted by deepest level reached"
	var players: Array[Dictionary] = _placeholder_roster().duplicate()
	players.append(_read_you_stats())
	players.sort_custom(_compare_players)
	var rank: int = 1
	for d in players:
		_list.add_child(_make_row(rank, d))
		rank += 1


func _compare_players(a: Dictionary, b: Dictionary) -> bool:
	if _sort_mode == SortMode.BY_SCORE:
		if int(a["best"]) != int(b["best"]):
			return int(a["best"]) > int(b["best"])
		return int(a["level"]) > int(b["level"])
	if int(a["level"]) != int(b["level"]):
		return int(a["level"]) > int(b["level"])
	return int(a["best"]) > int(b["best"])


func _row_panel_style(is_you: bool, top_rank: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_right = 16
	s.corner_radius_bottom_left = 16
	s.border_width_left = 3
	s.border_width_top = 3
	s.border_width_right = 3
	s.border_width_bottom = 4
	s.shadow_offset = Vector2(0, 3)
	s.shadow_size = 6
	if is_you:
		s.bg_color = Color(0.28, 0.22, 0.48, 0.98)
		s.border_color = Color(1, 0.88, 0.38, 1)
		s.shadow_color = Color(0.55, 0.35, 0.1, 0.4)
	elif top_rank:
		s.bg_color = Color(0.2, 0.18, 0.34, 0.96)
		s.border_color = Color(1, 0.82, 0.35, 0.85)
		s.shadow_color = Color(0.35, 0.25, 0.08, 0.35)
	else:
		s.bg_color = Color(0.16, 0.14, 0.26, 0.94)
		s.border_color = Color(0.42, 0.4, 0.55, 1)
		s.shadow_color = Color(0, 0, 0, 0.22)
	return s


func _make_row(place: int, d: Dictionary) -> PanelContainer:
	var is_you: bool = bool(d.get("is_you", false))
	var top_rank: bool = place == 1
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _row_panel_style(is_you, top_rank))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var rk := Label.new()
	rk.text = ("🏆 " if top_rank else "") + "#%d" % place
	rk.custom_minimum_size = Vector2(52, 0)
	rk.add_theme_font_size_override("font_size", 20)
	rk.add_theme_color_override("font_color", Color(1, 0.92, 0.55, 1) if top_rank else Color(0.88, 0.9, 1, 1))
	rk.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.14, 1))
	rk.add_theme_constant_override("outline_size", 4)
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(rk)
	var av := PanelContainer.new()
	av.custom_minimum_size = Vector2(48, 48)
	var av_st := StyleBoxFlat.new()
	av_st.bg_color = Color.from_hsv(float(d["hue"]), 0.52, 0.92, 1)
	av_st.border_color = Color(0.12, 0.08, 0.22, 1)
	av_st.set_border_width_all(2)
	av_st.corner_radius_top_left = 99
	av_st.corner_radius_top_right = 99
	av_st.corner_radius_bottom_right = 99
	av_st.corner_radius_bottom_left = 99
	av.add_theme_stylebox_override("panel", av_st)
	var av_ctr := CenterContainer.new()
	av.add_child(av_ctr)
	var ini := Label.new()
	ini.text = _initial(str(d["name"]))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_font_size_override("font_size", 22)
	ini.add_theme_color_override("font_color", Color(0.12, 0.1, 0.18, 1))
	ini.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))
	ini.add_theme_constant_override("outline_size", 3)
	av_ctr.add_child(ini)
	row.add_child(av)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	var nm := Label.new()
	nm.text = str(d["name"])
	nm.add_theme_font_size_override("font_size", 19)
	nm.add_theme_color_override("font_color", Color(0.98, 0.97, 1, 1))
	nm.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.14, 1))
	nm.add_theme_constant_override("outline_size", 3)
	mid.add_child(nm)
	var st := Label.new()
	st.text = "Lv. %d  ·  Best %s" % [int(d["level"]), _fmt_num(int(d["best"]))]
	if is_you:
		st.text += "  ·  This device"
	st.add_theme_font_size_override("font_size", 15)
	st.add_theme_color_override("font_color", Color(0.78, 0.84, 0.95, 1))
	mid.add_child(st)
	return panel


func _initial(name_str: String) -> String:
	if name_str.is_empty():
		return "?"
	return name_str.substr(0, 1).to_upper()


func _fmt_num(n: int) -> String:
	var s := str(abs(n))
	var tail := ""
	while s.length() > 3:
		tail = "," + s.substr(s.length() - 3, 3) + tail
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + tail


func _refresh_sort_visuals() -> void:
	var active := Color(1, 1, 1, 1)
	var dim := Color(0.74, 0.72, 0.88, 1)
	_btn_sort_score.modulate = active if _sort_mode == SortMode.BY_SCORE else dim
	_btn_sort_level.modulate = active if _sort_mode == SortMode.BY_LEVEL else dim
