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

## Rush Reliquary — exact layout (540×960 target)
const CARD_W: int = 210
const CARD_H: int = 230
const CARD_H_GAP: int = 24
const CARD_ROW_V_SEP: int = 28

@onready var _close_btn: Button = $Center/Panel/Margin/Root/FooterWrap/Footer/CloseBtn
@onready var _card_rows: VBoxContainer = $Center/Panel/Margin/Root/Scroll/Margin/CardRows


func _ready() -> void:
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


func _reliquary_card_stylebox(unlocked: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	var cr: int = 16
	s.corner_radius_top_left = cr
	s.corner_radius_top_right = cr
	s.corner_radius_bottom_right = cr
	s.corner_radius_bottom_left = cr
	s.content_margin_left = 0
	s.content_margin_top = 0
	s.content_margin_right = 0
	s.content_margin_bottom = 0
	if unlocked:
		s.bg_color = Color(0.48, 0.26, 0.78, 1)
		s.border_color = Color(1, 0.9, 0.42, 1)
		s.border_width_left = 4
		s.border_width_top = 4
		s.border_width_right = 4
		s.border_width_bottom = 5
		s.shadow_color = Color(0.95, 0.55, 1, 0.55)
		s.shadow_size = 18
		s.shadow_offset = Vector2(0, 6)
	else:
		s.bg_color = Color(0.3, 0.36, 0.68, 1)
		s.border_color = Color(0.82, 0.9, 1, 1)
		s.border_width_left = 3
		s.border_width_top = 3
		s.border_width_right = 3
		s.border_width_bottom = 4
		s.shadow_color = Color(0.45, 0.55, 1, 0.45)
		s.shadow_size = 14
		s.shadow_offset = Vector2(0, 5)
	return s


func _rebuild_grid() -> void:
	for c in _card_rows.get_children():
		c.queue_free()
	_card_rows.add_theme_constant_override("separation", CARD_ROW_V_SEP)

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

	var cards: Array[PanelContainer] = []
	for d in defs:
		cards.append(_make_card(d))

	var pair_w: int = CARD_W * 2 + CARD_H_GAP
	var i: int = 0
	while i < cards.size():
		if i + 1 < cards.size():
			var row := HBoxContainer.new()
			row.layout_mode = 2
			row.custom_minimum_size = Vector2(pair_w, CARD_H)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", CARD_H_GAP)
			row.add_child(cards[i])
			row.add_child(cards[i + 1])
			_card_rows.add_child(row)
			i += 2
		else:
			var solo := CenterContainer.new()
			solo.layout_mode = 2
			solo.custom_minimum_size = Vector2(pair_w, CARD_H)
			solo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			solo.add_child(cards[i])
			_card_rows.add_child(solo)
			i += 1


func _make_card(d: Dictionary) -> PanelContainer:
	var unlocked: bool = bool(d["unlocked"])
	var row := PanelContainer.new()
	row.layout_mode = 2
	row.custom_minimum_size = Vector2(CARD_W, CARD_H)
	row.clip_contents = true
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_theme_stylebox_override("panel", _reliquary_card_stylebox(unlocked))
	if not unlocked:
		row.modulate = Color(0.88, 0.9, 1, 1)

	var outer := MarginContainer.new()
	outer.layout_mode = 2
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_top", 14)
	outer.add_theme_constant_override("margin_left", 10)
	outer.add_theme_constant_override("margin_right", 10)
	outer.add_theme_constant_override("margin_bottom", 10)
	row.add_child(outer)

	var v := VBoxContainer.new()
	v.layout_mode = 2
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	outer.add_child(v)

	var icon_holder := CenterContainer.new()
	icon_holder.custom_minimum_size = Vector2(0, 50)
	icon_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.add_child(icon_holder)

	var g := Label.new()
	g.layout_mode = 2
	g.text = str(d["glyph"])
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	g.custom_minimum_size = Vector2(50, 50)
	g.add_theme_font_size_override("font_size", 40)
	icon_holder.add_child(g)

	var gap1 := Control.new()
	gap1.custom_minimum_size = Vector2(0, 10)
	gap1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap1.layout_mode = 2
	v.add_child(gap1)

	var title := Label.new()
	title.layout_mode = 2
	title.text = str(d["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.45, 1))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.06, 0.28, 1))
	title.add_theme_constant_override("outline_size", 5)
	v.add_child(title)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	gap2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap2.layout_mode = 2
	v.add_child(gap2)

	var st := Label.new()
	st.layout_mode = 2
	if unlocked:
		st.text = "Unlocked"
		st.add_theme_color_override("font_color", Color(0.45, 1, 0.72, 1))
	else:
		st.text = "🔒 Locked"
		st.add_theme_color_override("font_color", Color(0.82, 0.86, 1, 0.95))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_font_size_override("font_size", 22)
	st.add_theme_color_override("font_outline_color", Color(0.04, 0.1, 0.12, 1))
	st.add_theme_constant_override("outline_size", 2)
	v.add_child(st)

	var flavor := Label.new()
	flavor.layout_mode = 2
	flavor.text = str(d["flavor"]) if unlocked else str(d["hint"])
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.clip_text = true
	flavor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flavor.add_theme_font_size_override("font_size", 20)
	flavor.add_theme_color_override(
		"font_color",
		Color(0.96, 0.98, 1.0, 1) if unlocked else Color(0.86, 0.88, 0.98, 1)
	)
	flavor.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 1))
	flavor.add_theme_constant_override("outline_size", 2)
	flavor.add_theme_constant_override("line_spacing", 2)
	v.add_child(flavor)

	return row
