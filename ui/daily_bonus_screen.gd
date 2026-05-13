extends Control
class_name DailyBonusScreen

signal claim_pressed

@onready var title_label: Label = $Center/Panel/Margin/Root/Title
@onready var subtitle_label: Label = $Center/Panel/Margin/Root/Subtitle
@onready var status_label: Label = $Center/Panel/Margin/Root/StatusLabel
@onready var calendar_row1: HBoxContainer = $Center/Panel/Margin/Root/CalendarArea/CalendarRow1
@onready var calendar_row2: HBoxContainer = $Center/Panel/Margin/Root/CalendarArea/CalendarRow2
@onready var calendar_row3: HBoxContainer = $Center/Panel/Margin/Root/CalendarArea/CalendarRow3
@onready var claim_button: Button = $Center/Panel/Margin/Root/ClaimWrap/ClaimButton
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
	for row in [calendar_row1, calendar_row2, calendar_row3]:
		for c in row.get_children():
			c.queue_free()

	for d in range(1, 4):
		var st := _day_state(d, next_day, can_claim, streak_saved)
		var cell := _make_day_cell(d, st.completed, st.active, st.future)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		calendar_row1.add_child(cell)

	for d in range(4, 7):
		var st2 := _day_state(d, next_day, can_claim, streak_saved)
		var cell2 := _make_day_cell(d, st2.completed, st2.active, st2.future)
		cell2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		calendar_row2.add_child(cell2)

	var st7 := _day_state(7, next_day, can_claim, streak_saved)
	var day7 := _make_day_cell(7, st7.completed, st7.active, st7.future)
	day7.custom_minimum_size = Vector2(320, 200)
	calendar_row3.add_child(day7)


func _day_state(day: int, next_day: int, can_claim: bool, streak_saved: int) -> Dictionary:
	var completed: bool = false
	var active: bool = false
	var future: bool = false
	if can_claim:
		completed = day < next_day
		active = day == next_day
		future = day > next_day
	else:
		completed = day <= streak_saved
		future = day > streak_saved
	return {"completed": completed, "active": active, "future": future}


func _make_day_cell(day: int, completed: bool, active: bool, future: bool) -> PanelContainer:
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.4, 0.24, 0.08, 1)
		sb.border_color = Color(1, 0.95, 0.5, 1)
		sb.shadow_color = Color(1, 0.58, 0.15, 0.48)
		sb.shadow_size = 22
	elif completed:
		sb.bg_color = Color(0.1, 0.38, 0.26, 1)
		sb.border_color = Color(0.58, 1, 0.82, 1)
		sb.shadow_color = Color(0.3, 0.95, 0.6, 0.42)
		sb.shadow_size = 18
	else:
		sb.bg_color = Color(0.14, 0.18, 0.4, 1)
		sb.border_color = Color(0.65, 0.72, 1, 1)
		sb.shadow_color = Color(0.38, 0.48, 1, 0.35)
		sb.shadow_size = 16
	var bw: int = 5 if active else (4 if completed else 3)
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_right = 20
	sb.corner_radius_bottom_left = 20
	sb.content_margin_left = 14
	sb.content_margin_top = 12
	sb.content_margin_right = 14
	sb.content_margin_bottom = 12
	sb.shadow_offset = Vector2(0, 5)
	row.add_theme_stylebox_override("panel", sb)
	row.custom_minimum_size = Vector2(120, 188)
	if future:
		row.modulate = Color(0.9, 0.92, 1, 0.96)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	row.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)

	var sigil := Label.new()
	sigil.text = "Day %d" % day
	sigil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sigil.add_theme_font_size_override("font_size", 30)
	if active:
		sigil.add_theme_color_override("font_color", Color(1, 0.94, 0.55, 1))
	elif completed:
		sigil.add_theme_color_override("font_color", Color(0.85, 1, 0.92, 1))
	else:
		sigil.add_theme_color_override("font_color", Color(0.95, 0.93, 1, 1))
	if active or completed:
		sigil.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.22, 1))
		sigil.add_theme_constant_override("outline_size", 4)
	else:
		sigil.add_theme_color_override("font_outline_color", Color(0.06, 0.08, 0.22, 1))
		sigil.add_theme_constant_override("outline_size", 3)
	top.add_child(sigil)

	var mark := Label.new()
	if completed:
		mark.text = "✓"
		mark.add_theme_color_override("font_color", Color(0.35, 1, 0.72, 1))
		mark.add_theme_font_size_override("font_size", 34)
	elif active:
		mark.text = "★"
		mark.add_theme_color_override("font_color", Color(1, 0.82, 0.22, 1))
		mark.add_theme_font_size_override("font_size", 34)
	else:
		mark.text = "○"
		mark.add_theme_color_override("font_color", Color(0.75, 0.8, 1, 1))
		mark.add_theme_font_size_override("font_size", 30)
	top.add_child(mark)

	var body := Label.new()
	body.text = _reward_blurb(day)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 24)
	if future:
		body.add_theme_color_override("font_color", Color(0.94, 0.96, 1, 1))
		body.add_theme_color_override("font_outline_color", Color(0.06, 0.08, 0.2, 1))
		body.add_theme_constant_override("outline_size", 3)
	else:
		body.add_theme_color_override("font_color", Color(0.98, 0.99, 1, 1))
		body.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.12, 1))
		body.add_theme_constant_override("outline_size", 3)
	body.add_theme_constant_override("line_spacing", 4)
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
			return "Spark Sweep bomb charm"
		5:
			return "500 river coins"
		6:
			return "Fuse shield plate"
		7:
			return "Royal coffer bundle"
		_:
			return "—"
