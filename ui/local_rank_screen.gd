extends Control

const PlayerProfileResolve = preload("res://player_profile_resolve.gd")

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
@onready var _close_x: Button = $CloseX
@onready var _list: VBoxContainer = $Center/Panel/Margin/VBox/Scroll/ListMargins/ListHost
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
	_close_x.pressed.connect(_on_close)
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
	var xp: int = 0
	var av: int = 0
	var pp: Node = PlayerProfileResolve.node()
	if cfg.load(SAVE_PATH) == OK:
		best = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_BEST, 0)))
		var f: int = int(cfg.get_value(SAVE_SECTION, KEY_FURTHEST, -1))
		var p: int = int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1))
		lvl = clampi(f if f > 0 else p, 1, 999_999)
		if pp != null:
			xp = pp.read_xp_from_cfg(cfg)
			av = pp.read_avatar_from_cfg(cfg)
	var pl: int = pp.player_level_from_xp(xp) if pp != null else 1
	av = pp.clamp_avatar_to_unlocked(av, pl) if pp != null else 0
	var tit: String = pp.title_for_level(pl) if pp != null else "Coin Rookie"
	var bd: Dictionary = pp.rank_badge_for_level(pl) if pp != null else {"tier": "BRONZE", "rank": "III", "accent": Color.WHITE}
	return {
		"name": "You",
		"best": best,
		"level": lvl,
		"plevel": pl,
		"title": tit,
		"badge": "%s %s" % [str(bd.get("tier", "")), str(bd.get("rank", ""))],
		"emoji": pp.avatar_emoji(av) if pp != null else "👤",
		"hue": 0.14,
		"is_you": true,
	}


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


func _row_panel_style(is_you: bool, place: int) -> StyleBoxFlat:
	return CartoonStyleKit.rank_leaderboard_row(is_you, place)


func _make_row(place: int, d: Dictionary) -> PanelContainer:
	var is_you: bool = bool(d.get("is_you", false))
	var top_rank: bool = place == 1
	var podium: bool = place <= 3
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _row_panel_style(is_you, place))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if podium:
		panel.custom_minimum_size = Vector2(0, 128)
	else:
		panel.custom_minimum_size = Vector2(0, 112)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	var rk := Label.new()
	var medal := ""
	if place == 1:
		medal = "🥇 "
	elif place == 2:
		medal = "🥈 "
	elif place == 3:
		medal = "🥉 "
	rk.text = medal + "#%d" % place
	rk.custom_minimum_size = Vector2(100 if podium else 88, 0)
	rk.add_theme_font_size_override("font_size", 38 if podium else 34)
	rk.add_theme_color_override("font_color", Color(1, 0.92, 0.55, 1) if top_rank else Color(0.88, 0.9, 1, 1))
	rk.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.14, 1))
	rk.add_theme_constant_override("outline_size", 5)
	rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(rk)
	var av := PanelContainer.new()
	var av_side: int = 72 if podium else 64
	av.custom_minimum_size = Vector2(av_side, av_side)
	var av_st := StyleBoxFlat.new()
	av_st.bg_color = Color.from_hsv(float(d["hue"]), 0.52, 0.92, 1)
	av_st.border_color = Color(1, 0.88, 0.42, 0.95)
	av_st.set_border_width_all(4)
	av_st.shadow_color = Color(0, 0, 0, 0.4)
	av_st.shadow_size = 8
	av_st.shadow_offset = Vector2(0, 3)
	av_st.corner_radius_top_left = 99
	av_st.corner_radius_top_right = 99
	av_st.corner_radius_bottom_right = 99
	av_st.corner_radius_bottom_left = 99
	av.add_theme_stylebox_override("panel", av_st)
	var av_ctr := CenterContainer.new()
	av_ctr.layout_mode = 2
	av_ctr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av.add_child(av_ctr)
	var ini := Label.new()
	if str(d.get("emoji", "")).length() > 0:
		ini.text = str(d["emoji"])
	else:
		ini.text = _initial(str(d["name"]))
	ini.layout_mode = 2
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_font_size_override("font_size", 40 if podium else 36)
	ini.add_theme_color_override("font_color", Color(0.12, 0.1, 0.18, 1))
	ini.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))
	ini.add_theme_constant_override("outline_size", 3)
	av_ctr.add_child(ini)
	row.add_child(av)
	var mid := VBoxContainer.new()
	mid.layout_mode = 2
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	row.add_child(mid)
	var nm := Label.new()
	nm.text = str(d["name"])
	nm.add_theme_font_size_override("font_size", 36 if podium else 32)
	nm.add_theme_color_override("font_color", Color(0.98, 0.97, 1, 1))
	nm.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.14, 1))
	nm.add_theme_constant_override("outline_size", 4)
	mid.add_child(nm)
	var st := Label.new()
	if is_you:
		var pl: int = int(d.get("plevel", int(d["level"])))
		var tit: String = str(d.get("title", ""))
		var bd: String = str(d.get("badge", ""))
		st.text = "Rank %s · %s · P.Lv. %d\nStage %d · Best %s · This device" % [bd, tit, pl, int(d["level"]), _fmt_num(int(d["best"]))]
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		st.text = "Lv. %d  ·  Best %s" % [int(d["level"]), _fmt_num(int(d["best"]))]
	st.add_theme_font_size_override("font_size", 30 if podium else 28)
	st.add_theme_color_override("font_color", Color(0.88, 0.93, 1, 1))
	st.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.16, 1))
	st.add_theme_constant_override("outline_size", 4 if podium else 3)
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
