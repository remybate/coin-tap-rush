extends Control
class_name ShopPopup

## Placeholder treasure shop — purchases/ads are simulated (no IAP yet).

signal closed
signal toast_requested(title: String, body: String)

@onready var _close_x: Button = $CloseX
@onready var _close_btn: Button = $Center/Panel/Margin/Root/FooterRow/CloseBtn
@onready var _watch_ad_btn: Button = $Center/Panel/Margin/Root/FooterRow/WatchAdBtn
@onready var _items_host: VBoxContainer = $Center/Panel/Margin/Root/Scroll/Margin/ItemsHost


func _ready() -> void:
	_close_x.pressed.connect(_on_close)
	_close_btn.pressed.connect(_on_close)
	_watch_ad_btn.pressed.connect(_on_watch_ad)
	_build_items()


func open_shop() -> void:
	visible = true


func close_shop() -> void:
	visible = false
	closed.emit()


func _on_close() -> void:
	AudioService.play_button_click()
	close_shop()


func _on_watch_ad() -> void:
	AudioService.play_button_click()
	toast_requested.emit(
		"Sponsor Glint",
		"Ad rewards will land here in a future update. Picture a 15-second sparkle break, then bonus coins!"
	)


func _on_buy(item_title: String, price: String) -> void:
	AudioService.play_button_click()
	toast_requested.emit(
		"Treasure Emporium",
		"You tapped Buy for \"%s\" (%s). Payments are not connected yet — this is a safe preview only."
		% [item_title, price]
	)


func _build_items() -> void:
	for c in _items_host.get_children():
		c.queue_free()
	var catalog: Array[Dictionary] = [
		{
			"title": "Coin Pack +500",
			"desc": "A fat stack of vault tokens for skins and future upgrades.",
			"price": "$2.99",
		},
		{
			"title": "Extra Life",
			"desc": "One bonus heart for the next run — clutch saves when the rush tightens.",
			"price": "$1.99",
		},
		{
			"title": "Magnet Booster",
			"desc": "For one stage, good taps pull nearby shine toward your lane.",
			"price": "$0.99",
		},
		{
			"title": "Shield Booster",
			"desc": "Shrug off the next bomb tap once — use it when the screen gets spicy.",
			"price": "$0.99",
		},
		{
			"title": "Slow Motion Booster",
			"desc": "A few seconds of mellow tempo so you can line up perfect taps.",
			"price": "$0.99",
		},
	]
	for entry in catalog:
		_items_host.add_child(_make_row(entry["title"], entry["desc"], entry["price"]))


func _make_row(title: String, desc: String, price: String) -> PanelContainer:
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.16, 0.95)
	sb.border_color = Color(0.95, 0.72, 0.28, 0.55)
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

	var margin := MarginContainer.new()
	row.add_child(margin)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	margin.add_child(h)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(texts)

	var lt := Label.new()
	lt.text = title
	lt.add_theme_font_size_override("font_size", 22)
	lt.add_theme_color_override("font_color", Color(1, 0.88, 0.45, 1))
	texts.add_child(lt)

	var ld := Label.new()
	ld.text = desc
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ld.add_theme_font_size_override("font_size", 18)
	ld.add_theme_color_override("font_color", Color(0.82, 0.9, 0.98, 0.92))
	texts.add_child(ld)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	h.add_child(right)

	var price_lbl := Label.new()
	price_lbl.text = price
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_lbl.add_theme_font_size_override("font_size", 20)
	price_lbl.add_theme_color_override("font_color", Color(0.75, 1, 0.85, 1))
	right.add_child(price_lbl)

	var buy := Button.new()
	buy.text = "Buy"
	buy.custom_minimum_size = Vector2(120, 48)
	buy.add_theme_font_size_override("font_size", 20)
	buy.pressed.connect(_on_buy.bind(title, price))
	right.add_child(buy)

	return row
