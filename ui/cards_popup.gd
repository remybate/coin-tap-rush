extends Control
class_name CardsPopup

signal closed

const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SAVE_SECTION: String = "progress"
const KEY_PROGRESSION: String = "saved_progression_level"
const KEY_STAT_GLEAMS: String = "stat_gleams_collected"
const KEY_STAT_BOMBS_DODGED: String = "stat_bombs_dodged"
const KEY_STAT_MAX_COMBO: String = "stat_max_combo_streak"
const KEY_BOOST_LIGHTNING: String = "booster_lightning"
const KEY_BOOST_SHIELD: String = "booster_shield"

@onready var _close_x: Button = $CloseX
@onready var _close_btn: Button = $Center/Panel/Margin/Root/Footer/CloseBtn
@onready var _card_grid: GridContainer = $Center/Panel/Margin/Root/Scroll/Margin/CardGrid


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_close_btn.pressed.connect(_on_close)


func open_cards() -> void:
	_rebuild_grid()
	visible = true


func close_cards() -> void:
	visible = false
	closed.emit()


func _on_close() -> void:
	AudioService.play_button_click()
	close_cards()


func _rebuild_grid() -> void:
	for c in _card_grid.get_children():
		c.queue_free()

	var cfg := ConfigFile.new()
	var prog: int = 1
	var gleams: int = 0
	var bombs: int = 0
	var combo_best: int = 0
	var lightning: int = 0
	var shield: int = 0
	if cfg.load(SAVE_PATH) == OK:
		prog = maxi(1, int(cfg.get_value(SAVE_SECTION, KEY_PROGRESSION, 1)))
		gleams = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_GLEAMS, 0)))
		bombs = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_BOMBS_DODGED, 0)))
		combo_best = maxi(0, int(cfg.get_value(SAVE_SECTION, KEY_STAT_MAX_COMBO, 0)))
		lightning = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_LIGHTNING, 0)), 0, 99)
		shield = clampi(int(cfg.get_value(SAVE_SECTION, KEY_BOOST_SHIELD, 0)), 0, 99)

	var defs: Array[Dictionary] = [
		{
			"id": "gold",
			"title": "River Ducat",
			"kind": "Gold Coin",
			"glyph": "🪙",
			"flavor": "The classic vault disc — warm brass echoing down the chute.",
			"unlocked": gleams >= 30,
			"hint": "Collect 30 gleams in the rush.",
		},
		{
			"id": "diamond",
			"title": "Polar Spire",
			"kind": "Diamond",
			"glyph": "💎",
			"flavor": "A frozen spark from the map’s deepest gallery.",
			"unlocked": prog >= 5,
			"hint": "Reach vault depth 5 on the progression map.",
		},
		{
			"id": "chest",
			"title": "Lucky Coffer",
			"kind": "Lucky Chest",
			"glyph": "📦",
			"flavor": "Hinges hum when fortune leans your way.",
			"unlocked": combo_best >= 7 or gleams >= 200,
			"hint": "Chain a 7-tap streak or gather 200 gleams.",
		},
		{
			"id": "shield",
			"title": "Fuse Aegis",
			"kind": "Shield",
			"glyph": "🛡️",
			"flavor": "Turns one cherry fuse into harmless smoke.",
			"unlocked": bombs >= 12 or shield >= 1,
			"hint": "Drift past 12 bombs or hold a shield plate.",
		},
		{
			"id": "magnet",
			"title": "Gleam Lure",
			"kind": "Magnet",
			"glyph": "🧲",
			"flavor": "Your magnet charms tug drops into friendlier arcs.",
			"unlocked": lightning >= 6 or prog >= 7,
			"hint": "Stock 6 gleam-drifts or reach vault depth 7.",
		},
	]

	for d in defs:
		_card_grid.add_child(_make_card(d))


func _make_card(d: Dictionary) -> PanelContainer:
	var unlocked: bool = bool(d["unlocked"])
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	if unlocked:
		sb.bg_color = Color(0.1, 0.08, 0.16, 0.96)
		sb.border_color = Color(0.95, 0.7, 0.35, 0.85)
	else:
		sb.bg_color = Color(0.05, 0.06, 0.09, 0.94)
		sb.border_color = Color(0.35, 0.34, 0.42, 0.5)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.content_margin_left = 12
	sb.content_margin_top = 12
	sb.content_margin_right = 12
	sb.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", sb)
	row.custom_minimum_size = Vector2(158, 196)
	if not unlocked:
		row.modulate = Color(0.72, 0.74, 0.82, 1)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	row.add_child(v)

	var g := Label.new()
	g.text = str(d["glyph"])
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.add_theme_font_size_override("font_size", 40)
	v.add_child(g)

	var kind := Label.new()
	kind.text = str(d["kind"])
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.add_theme_font_size_override("font_size", 15)
	kind.add_theme_color_override("font_color", Color(0.75, 0.95, 0.88, 1))
	v.add_child(kind)

	var title := Label.new()
	title.text = str(d["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.86, 0.48, 1))
	v.add_child(title)

	var st := Label.new()
	if unlocked:
		st.text = "Unlocked"
		st.add_theme_color_override("font_color", Color(0.55, 0.95, 0.68, 1))
	else:
		st.text = "🔒 Locked"
		st.add_theme_color_override("font_color", Color(0.78, 0.8, 0.9, 0.85))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_font_size_override("font_size", 15)
	v.add_child(st)

	var flavor := Label.new()
	flavor.text = str(d["flavor"]) if unlocked else str(d["hint"])
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.add_theme_font_size_override("font_size", 14)
	flavor.add_theme_color_override(
		"font_color",
		Color(0.86, 0.9, 1.0, 0.92) if unlocked else Color(0.7, 0.72, 0.8, 0.88)
	)
	v.add_child(flavor)

	return row
