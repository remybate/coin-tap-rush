extends Control

## Full vault shop UI — placeholder prices only; emits toasts on taps.

signal closed
signal toast_requested(title: String, body: String)

@onready var _dim: ColorRect = $Dim
@onready var _close_x: Button = $CloseX
@onready var _list: VBoxContainer = $MainMargin/MainPanel/Margin/VBox/Scroll/ListHost
@onready var _watch_ad_btn: Button = $MainMargin/MainPanel/Margin/VBox/Footer/FooterColumn/WatchAdBtn
@onready var _close_btn: Button = $MainMargin/MainPanel/Margin/VBox/Footer/FooterColumn/CloseBtn


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
	var coin_rows := VBoxContainer.new()
	coin_rows.add_theme_constant_override("separation", 18)
	coin_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(coin_rows)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 16)
	row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_rows.add_child(row1)
	coin_rows.add_child(row2)
	var coin_packs: Array[Dictionary] = [
		{"emoji": "🪙", "title": "Pocket Stack", "desc": "+250 vault coins", "price": "$0.99", "accent": Color(0.95, 0.72, 0.22)},
		{"emoji": "💰", "title": "Satchel", "desc": "+1,200 coins", "price": "$4.99", "accent": Color(0.98, 0.55, 0.28)},
		{"emoji": "🏦", "title": "Vault Crate", "desc": "+5,000 coins", "price": "$14.99", "accent": Color(1.0, 0.82, 0.35)},
		{"emoji": "✨", "title": "Mega Mint", "desc": "+25,000 coins", "price": "$39.99", "accent": Color(0.45, 0.92, 0.55)},
	]
	for i in range(2):
		var c := _make_pack_card(coin_packs[i], false, true)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(c)
	for i in range(2, 4):
		var c2 := _make_pack_card(coin_packs[i], false, true)
		c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(c2)
	_list.add_child(_section_title("Booster packs"))
	var boost_wrap := VBoxContainer.new()
	boost_wrap.add_theme_constant_override("separation", 16)
	boost_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(boost_wrap)
	var boosters: Array[Dictionary] = [
		{"emoji": "🌀", "title": "Rush Trio", "desc": "Three surprise boosters — magnet, slow, or shield mix.", "price": "$3.99", "accent": Color(0.62, 0.38, 0.98)},
		{"emoji": "⚡", "title": "Power Hour", "desc": "Double charges on every booster for your next streak of runs.", "price": "$7.99", "accent": Color(0.95, 0.35, 0.72)},
	]
	for d in boosters:
		boost_wrap.add_child(_make_pack_card(d, true, false))
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
			true,
			false
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
			true,
			false
		)
	)


func _section_title(text: String) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 38)
	lb.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	lb.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.35, 1))
	lb.add_theme_constant_override("outline_size", 7)
	return lb


func _make_pack_card(d: Dictionary, wide: bool, coin_tile: bool) -> PanelContainer:
	var accent: Color = d["accent"]
	var hero: bool = bool(d.get("hero", false))
	var pack_style: int = 1 if coin_tile else 2
	var frame: StyleBoxFlat = CartoonStyleKit.shop_pack_frame(accent, hero, pack_style)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", frame)
	if wide:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif coin_tile:
		panel.custom_minimum_size = Vector2(0, 276)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		panel.custom_minimum_size = Vector2(158, 0)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14 if (wide or coin_tile) else 10)
	panel.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14 if (wide or coin_tile) else 10)
	root.add_child(top)
	var emoji := Label.new()
	emoji.text = str(d.get("emoji", "💎"))
	if coin_tile:
		emoji.add_theme_font_size_override("font_size", 64)
	elif hero:
		emoji.add_theme_font_size_override("font_size", 62)
	elif wide:
		emoji.add_theme_font_size_override("font_size", 54)
	else:
		emoji.add_theme_font_size_override("font_size", 40)
	top.add_child(emoji)
	var head_col := VBoxContainer.new()
	head_col.add_theme_constant_override("separation", 8 if (wide or coin_tile) else 6)
	head_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head_col)
	var title := Label.new()
	var badge: String = str(d.get("badge", ""))
	title.text = str(d["title"]) + (("  ·  " + badge) if not badge.is_empty() else "")
	if coin_tile:
		title.add_theme_font_size_override("font_size", 34)
	elif hero:
		title.add_theme_font_size_override("font_size", 52)
	elif wide:
		title.add_theme_font_size_override("font_size", 46)
	else:
		title.add_theme_font_size_override("font_size", 26 if hero else 24)
	title.add_theme_color_override("font_color", Color(0.98, 0.97, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.2, 1))
	title.add_theme_constant_override("outline_size", 6 if (wide or coin_tile) else 4)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head_col.add_child(title)
	var desc := Label.new()
	desc.text = str(d["desc"])
	if coin_tile:
		desc.add_theme_font_size_override("font_size", 28)
	elif wide:
		desc.add_theme_font_size_override("font_size", 34)
	else:
		desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_constant_override("line_spacing", 6 if wide else 4)
	desc.add_theme_color_override("font_color", Color(0.88, 0.93, 0.99, 0.96))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head_col.add_child(desc)
	var bot := HBoxContainer.new()
	bot.add_theme_constant_override("separation", 16)
	bot.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bot)
	var price := Label.new()
	price.text = str(d["price"])
	if coin_tile:
		price.add_theme_font_size_override("font_size", 34)
	elif hero:
		price.add_theme_font_size_override("font_size", 48)
	elif wide:
		price.add_theme_font_size_override("font_size", 42)
	else:
		price.add_theme_font_size_override("font_size", 26 if hero else 22)
	price.add_theme_color_override("font_color", Color(0.78, 1.0, 0.9, 1))
	price.add_theme_color_override("font_outline_color", Color(0.05, 0.12, 0.1, 1))
	price.add_theme_constant_override("outline_size", 6 if (wide or coin_tile) else 4)
	bot.add_child(price)
	var buy := Button.new()
	buy.text = "Buy"
	buy.focus_mode = Control.FOCUS_NONE
	var chip_style: int = 1 if coin_tile else 2
	if coin_tile:
		buy.custom_minimum_size = Vector2(168, 80)
		buy.add_theme_font_size_override("font_size", 30)
	elif hero:
		buy.custom_minimum_size = Vector2(248, 96)
		buy.add_theme_font_size_override("font_size", 38)
	elif wide:
		buy.custom_minimum_size = Vector2(228, 88)
		buy.add_theme_font_size_override("font_size", 34)
	else:
		buy.custom_minimum_size = Vector2(168 if hero else 140, 62 if hero else 56)
		buy.add_theme_font_size_override("font_size", 24 if hero else 22)
		chip_style = 0
	CartoonStyleKit.style_buy_chip(buy, accent, chip_style)
	var t := str(d["title"])
	var p := str(d["price"])
	buy.pressed.connect(_on_buy.bind(t, p))
	bot.add_child(buy)
	return panel
