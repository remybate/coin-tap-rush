extends Control
class_name DailyBonusScreen

signal claim_pressed

@onready var title_label: Label = $Center/Panel/Margin/Root/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/Root/Subtitle
@onready var status_label: Label = $Center/Panel/Margin/Root/StatusLabel
@onready var calendar_grid: GridContainer = $Center/Panel/Margin/Root/CalendarScroll/CalendarGrid
@onready var claim_button: Button = $Center/Panel/Margin/Root/ClaimRow/ClaimButton
@onready var close_x: Button = $CloseX


func _ready() -> void:
	claim_button.pressed.connect(_on_claim_pressed)
	close_x.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	AudioService.play_button_click()
	hide_bonus()


func _on_claim_pressed() -> void:
	if claim_button.disabled:
		return
	AudioService.play_button_click()
	claim_pressed.emit()


func hide_bonus() -> void:
	visible = false


func present(next_day: int, can_claim: bool, streak_saved: int) -> void:
	title_label.text = "Seven-Sigil Vault Calendar"
	subtitle_label.text = "Each dawn opens one sigil along the vault corridor. Claim in order while your streak holds — miss a day and the brass counter resets to day one."
	_rebuild_calendar(clampi(next_day, 1, 7), can_claim, clampi(streak_saved, 0, 7))
	if can_claim:
		status_label.text = "Today’s wax seal is ready. Claim to pour coins, charms, and booster relics straight into your run kit."
		claim_button.disabled = false
		claim_button.text = "Claim reward"
	else:
		status_label.text = "You already claimed today’s reward. Come back tomorrow when the next sigil warms up."
		claim_button.disabled = true
		claim_button.text = "Come back tomorrow"
	visible = true


func _rebuild_calendar(next_day: int, can_claim: bool, streak_saved: int) -> void:
	for c in calendar_grid.get_children():
		c.queue_free()
	for d in range(1, 8):
		var completed: bool = false
		var active: bool = false
		var future: bool = false
		if can_claim:
			completed = d < next_day
			active = d == next_day
			future = d > next_day
		else:
			completed = d <= streak_saved
			future = d > streak_saved
		calendar_grid.add_child(_make_day_cell(d, completed, active, future))


func _make_day_cell(day: int, completed: bool, active: bool, future: bool) -> PanelContainer:
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.14, 0.1, 0.06, 0.96)
		sb.border_color = Color(1, 0.78, 0.28, 0.95)
	elif completed:
		sb.bg_color = Color(0.08, 0.12, 0.09, 0.95)
		sb.border_color = Color(0.45, 0.88, 0.55, 0.75)
	else:
		sb.bg_color = Color(0.05, 0.06, 0.1, 0.92)
		sb.border_color = Color(0.38, 0.35, 0.48, 0.45)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	sb.content_margin_left = 10
	sb.content_margin_top = 8
	sb.content_margin_right = 10
	sb.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", sb)
	row.custom_minimum_size = Vector2(118, 108)
	if future:
		row.modulate = Color(0.65, 0.68, 0.78, 0.88)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	v.add_child(top)

	var sigil := Label.new()
	sigil.text = "Day %d" % day
	sigil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sigil.add_theme_font_size_override("font_size", 17)
	sigil.add_theme_color_override("font_color", Color(1, 0.86, 0.45, 1) if active else Color(0.88, 0.9, 0.98, 0.95))
	top.add_child(sigil)

	var mark := Label.new()
	if completed:
		mark.text = "✓"
		mark.add_theme_color_override("font_color", Color(0.5, 0.95, 0.65, 1))
	elif active:
		mark.text = "◆"
		mark.add_theme_color_override("font_color", Color(1, 0.82, 0.35, 1))
	else:
		mark.text = "·"
		mark.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68, 0.85))
	mark.add_theme_font_size_override("font_size", 18)
	top.add_child(mark)

	var body := Label.new()
	body.text = _reward_blurb(day)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.9))
	v.add_child(body)

	return row


func _reward_blurb(day: int) -> String:
	match clampi(day, 1, 7):
		1:
			return "100 river coins"
		2:
			return "+1 heart reserve"
		3:
			return "250 river coins"
		4:
			return "Gleam magnet charm"
		5:
			return "500 river coins"
		6:
			return "Fuse shield plate"
		7:
			return "Royal coffer bundle"
		_:
			return "—"
