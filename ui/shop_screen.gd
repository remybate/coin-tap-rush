extends Control

## Full vault shop UI — placeholder prices only; emits toasts on taps.

signal closed
signal toast_requested(title: String, body: String)

@onready var _dim: ColorRect = $Dim
@onready var _close_x: Button = $CloseX
@onready var _list: VBoxContainer = $MainMargin/MainPanel/Margin/VBox/Scroll/ListHost
@onready var _watch_ad_btn: Button = $MainMargin/MainPanel/Margin/VBox/FooterRow/WatchAdBtn
@onready var _close_btn: Button = $MainMargin/MainPanel/Margin/VBox/FooterRow/CloseBtn


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_close_btn.pressed.connect(_on_close)
	_watch_ad_btn.pressed.connect(_on_watch_ad)
	_dim.gui_input.connect(_on_dim_input)
	_build_shop()
	hide()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()


func open_shop() -> void:
	show()


func close_shop() -> void:
	hide()
	closed.emit()


func _on_close() -> void:
	AudioService.play_button_click()
	close_shop()


func _on_watch_ad() -> void:
	AudioService.play_button_click()
	toast_requested.emit(
		"Sponsor Glint",
		"Ad rewards will plug in later — for now, enjoy this sparkle-free preview."
	)


func _on_buy(item_title: String, price: String) -> void:
	AudioService.play_button_click()
	toast_requested.emit(
		"Treasure Emporium",
		"You chose \"%s\" (%s). No real charges yet — safe UI rehearsal only."
		% [item_title, price]
	)


func _build_shop() -> void:
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(_section_title("Coin packs"))
	var coin_flow := HFlowContainer.new()
	coin_flow.add_theme_constant_override("h_separation", 12)
	coin_flow.add_theme_constant_override("v_separation", 12)
	coin_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(coin_flow)
	var coin_packs: Array[Dictionary] = [
		{"emoji": "🪙", "title": "Pocket Stack", "desc": "+250 vault coins", "price": "$0.99", "accent": Color(0.95, 0.72, 0.22)},
		{"emoji": "💰", "title": "Satchel", "desc": "+1,200 coins", "price": "$4.99", "accent": Color(0.98, 0.55, 0.28)},
		{"emoji": "🏦", "title": "Vault Crate", "desc": "+5,000 coins", "price": "$14.99", "accent": Color(1.0, 0.82, 0.35)},
		{"emoji": "✨", "title": "Mega Mint", "desc": "+25,000 coins", "price": "$39.99", "accent": Color(0.45, 0.92, 0.55)},
	]
	for d in coin_packs:
		coin_flow.add_child(_make_pack_card(d, false))
	_list.add_child(_section_title("Booster packs"))
	var boost_wrap := VBoxContainer.new()
	boost_wrap.add_theme_constant_override("separation", 12)
	boost_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(boost_wrap)
	var boosters: Array[Dictionary] = [
		{"emoji": "🌀", "title": "Rush Trio", "desc": "Three surprise boosters — magnet, slow, or shield mix.", "price": "$3.99", "accent": Color(0.62, 0.38, 0.98)},
		{"emoji": "⚡", "title": "Power Hour", "desc": "Double charges on every booster for your next streak of runs.", "price": "$7.99", "accent": Color(0.95, 0.35, 0.72)},
	]
	for d in boosters:
		boost_wrap.add_child(_make_pack_card(d, true))
	_list.add_child(_section_title("Remove ads"))
	_list.add_child(
		_make_pack_card(
			{
				"emoji": "📵",
				"title": "No Ads Pass",
				"desc": "Placeholder — quiet runs with no interstitials once billing is wired.",
				"price": "$9.99",
				"accent": Color(0.38, 0.55, 0.95),
				"badge": "PLACEHOLDER",
			},
			true
		)
	)
	_list.add_child(_section_title("Starter bundle"))
	_list.add_child(
		_make_pack_card(
			{
				"emoji": "🎁",
				"title": "Starter Vault Bundle",
				"desc": "Chunk of coins + a taste of each booster. One-time welcome deal (preview).",
				"price": "$2.99",
				"accent": Color(0.28, 0.88, 0.92),
				"badge": "BEST VALUE",
				"hero": true,
			},
			true
		)
	)


func _section_title(text: String) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 24)
	lb.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	lb.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.35, 1))
	lb.add_theme_constant_override("outline_size", 5)
	return lb


func _make_pack_card(d: Dictionary, wide: bool) -> PanelContainer:
	var accent: Color = d["accent"]
	var hero: bool = bool(d.get("hero", false))
	var panel := PanelContainer.new()
	var frame := StyleBoxFlat.new()
	var bg := accent.lerp(Color(0.06, 0.05, 0.12), 0.72)
	frame.bg_color = bg
	frame.border_color = accent.lerp(Color.WHITE, 0.35)
	var bw: int = 5 if hero else 3
	frame.set_border_width_all(bw)
	frame.corner_radius_top_left = 20
	frame.corner_radius_top_right = 20
	frame.corner_radius_bottom_right = 20
	frame.corner_radius_bottom_left = 20
	frame.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	frame.shadow_size = 18 if hero else 10
	frame.shadow_offset = Vector2(0, 6)
	frame.content_margin_left = 16
	frame.content_margin_top = 14
	frame.content_margin_right = 16
	frame.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", frame)
	if wide:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		panel.custom_minimum_size = Vector2(158, 0)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	var emoji := Label.new()
	emoji.text = str(d.get("emoji", "💎"))
	emoji.add_theme_font_size_override("font_size", 36 if hero else 30)
	top.add_child(emoji)
	var head_col := VBoxContainer.new()
	head_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head_col)
	var title := Label.new()
	var badge: String = str(d.get("badge", ""))
	title.text = str(d["title"]) + (("  ·  " + badge) if not badge.is_empty() else "")
	title.add_theme_font_size_override("font_size", 22 if hero else 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.97, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.2, 1))
	title.add_theme_constant_override("outline_size", 4)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head_col.add_child(title)
	var desc := Label.new()
	desc.text = str(d["desc"])
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.85, 0.9, 0.98, 0.95))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head_col.add_child(desc)
	var bot := HBoxContainer.new()
	bot.add_theme_constant_override("separation", 12)
	bot.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bot)
	var price := Label.new()
	price.text = str(d["price"])
	price.add_theme_font_size_override("font_size", 26 if hero else 22)
	price.add_theme_color_override("font_color", Color(0.75, 1.0, 0.88, 1))
	price.add_theme_color_override("font_outline_color", Color(0.05, 0.12, 0.1, 1))
	price.add_theme_constant_override("outline_size", 4)
	bot.add_child(price)
	var buy := Button.new()
	buy.text = "Buy"
	buy.focus_mode = Control.FOCUS_NONE
	buy.custom_minimum_size = Vector2(160 if hero else 132, 58 if hero else 52)
	buy.add_theme_font_size_override("font_size", 22 if hero else 20)
	_style_buy_button(buy, accent)
	var t := str(d["title"])
	var p := str(d["price"])
	buy.pressed.connect(_on_buy.bind(t, p))
	bot.add_child(buy)
	return panel


func _style_buy_button(btn: Button, accent: Color) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = accent.lerp(Color(0.15, 0.1, 0.25), 0.25)
	n.border_color = Color(1, 0.95, 0.75, 1)
	n.set_border_width_all(3)
	n.corner_radius_top_left = 16
	n.corner_radius_top_right = 16
	n.corner_radius_bottom_right = 16
	n.corner_radius_bottom_left = 16
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = accent.lerp(Color.WHITE, 0.15)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = accent.lerp(Color.BLACK, 0.35)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", n)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.15, 1))
	btn.add_theme_constant_override("outline_size", 4)
